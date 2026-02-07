# frozen_string_literal: true

# Demo data generator: produces a hash of budget template + influenced-random
# transactions. No DB. Output can be written to CSV for inspection or fed
# into seed/creators later.
#
# Run: ruby lib/demo_data_generator.rb
#   Writes tmp/demo/demo_transactions.csv and tmp/demo/demo_summary.csv

require "csv"
require "date"
require "fileutils"
require "set"

class DemoDataGenerator
  # Category key => { pct (0-100) or nil for income, category_name, subcategory_name, vendors: [], cadence: ... }
  DEMO_TEMPLATE = {
    income: {
      pct: nil,
      category_name: "Income Parent",
      subcategory_name: "Income",
      vendors: [ "Employer" ],
      cadence: { per_month: 1 }
    },
    rent: {
      pct: 30,
      category_name: "Monthly",
      subcategory_name: "Rent",
      vendors: [ "Landlord LLC" ],
      cadence: { per_month: 1 }
    },
    groceries: {
      pct: 12,
      category_name: "Everyday",
      subcategory_name: "Groceries",
      vendors: [ "Safeway", "Whole Foods", "Trader Joe's", "Kroger", "Costco" ],
      cadence: { per_month: [ 2, 4 ] },
      amount_variance: 0.15
    },
    fuel: {
      pct: 5,
      category_name: "Everyday",
      subcategory_name: "Fuel",
      vendors: [ "Shell", "Chevron", "Costco Gas", "BP", "Exxon" ],
      cadence: { per_month: [ 2, 4 ] },
      amount_variance: 0.15
    },
    restaurants: {
      pct: 8,
      category_name: "Everyday",
      subcategory_name: "Restaurants",
      vendors: [ "Chipotle", "Local Bistro", "Starbucks", "Pizza Place", "Taco Bell" ],
      cadence: { per_month: [ 4, 10 ] },
      amount_variance: 0.15
    },
    subscriptions: {
      pct: 3,
      category_name: "Monthly",
      subcategory_name: "News Subscriptions",
      vendors: [ "Netflix", "Spotify", "HBO Max", "Disney+", "YouTube Premium" ],
      cadence: { per_month: 3 }
    },
    utilities: {
      pct: 4,
      category_name: "Monthly",
      subcategory_name: "Internet & Utilities",
      vendors: [ "Electric Co", "Water Co", "Gas Utility", "Internet Provider" ],
      cadence: { per_month: [ 1, 2 ] }
    },
    phone: {
      pct: 2,
      category_name: "Monthly",
      subcategory_name: "Phone",
      vendors: [ "Verizon" ],
      cadence: { per_month: 1 }
    },
    insurance: {
      pct: 4,
      category_name: "Monthly",
      subcategory_name: "Car Insurance",
      vendors: [ "Geico" ],
      cadence: { per_year: 2 }
    },
    entertainment: {
      pct: 5,
      category_name: "Everyday",
      subcategory_name: "Entertainment",
      vendors: [ "AMC Theaters", "Steam", "Concert Venue", "Bookstore" ],
      cadence: { per_month: [ 2, 6 ] },
      amount_variance: 0.15
    },
    household: {
      pct: 3,
      category_name: "Everyday",
      subcategory_name: "Household & Cleaning",
      vendors: [ "Target", "Walmart", "Home Depot", "Amazon" ],
      cadence: { per_month: [ 1, 3 ] },
      amount_variance: 0.15
    }
  }.freeze

  DEFAULT_TAKE_HOME_RATIO = 0.70
  DEFAULT_SALARY_GROWTH_RATE = 0

  attr_reader :annual_salary_dollars, :take_home_ratio, :start_date, :end_date, :seed, :rng, :salary_growth_rate

  def initialize(annual_salary_dollars:, start_date:, end_date:, take_home_ratio: DEFAULT_TAKE_HOME_RATIO, salary_growth_rate: DEFAULT_SALARY_GROWTH_RATE, seed: nil)
    @annual_salary_dollars = annual_salary_dollars
    @take_home_ratio = take_home_ratio
    @start_date = start_date
    @end_date = end_date
    @salary_growth_rate = salary_growth_rate
    @seed = seed
    @rng = seed ? Random.new(seed) : Random.new
  end

  # Returns full hash: :meta, :budget, :categories, :accounts, :vendors, :transactions, :summary
  def generate
    transactions = []
    summary_by_category = Hash.new { |h, k| h[k] = { target_annual_cents: 0, generated_annual_cents: 0, transaction_count: 0 } }

    DEMO_TEMPLATE.each do |cat_key, config|
      if config[:pct].nil?
        summary_by_category[cat_key][:target_pct] = nil
        summary_by_category[cat_key][:target_annual_cents] = (annual_salary_dollars * 100 * take_home_ratio).round
      else
        pct = config[:pct]
        summary_by_category[cat_key][:target_pct] = pct
        summary_by_category[cat_key][:target_annual_cents] = (annual_salary_dollars * 100 * take_home_ratio * (pct / 100.0)).round
      end
    end

    per_year_months = compute_per_year_months

    monthly_dates.each_with_index do |month_start, month_index|
      month_end = month_start.end_of_month
      year_index = month_index / 12
      effective_salary = (annual_salary_dollars * (1 + salary_growth_rate)**year_index).round

      DEMO_TEMPLATE.each do |cat_key, config|
        if config[:pct].nil?
          monthly_budget_cents = (effective_salary * 100 * take_home_ratio / 12).round
          annual_budget_cents = (effective_salary * 100 * take_home_ratio).round
        else
          pct = config[:pct]
          monthly_budget_cents = (effective_salary * 100 * take_home_ratio * (pct / 100.0) / 12).round
          annual_budget_cents = (effective_salary * 100 * take_home_ratio * (pct / 100.0)).round
        end

        n = transaction_count_for(config[:cadence], month_start, cat_key, per_year_months)
        next if n <= 0

        amounts_cents = amounts_for_month(config, n, monthly_budget_cents, annual_budget_cents)
        dates = pick_dates_in_month(month_start, month_end, n, cat_key)

        vendors = config[:vendors]
        category_name = config[:category_name]
        subcategory_name = config[:subcategory_name]

        n.times do |i|
          vendor_name = vendors[rng.rand(vendors.size)]
          amount_cents = amounts_cents[i]
          date = dates[i]
          transactions << {
            date: date,
            category_key: cat_key,
            category_name: category_name,
            subcategory_name: subcategory_name,
            vendor_name: vendor_name,
            amount_cents: amount_cents,
            memo: memo_for(cat_key, vendor_name)
          }
          summary_by_category[cat_key][:generated_annual_cents] += amount_cents
          summary_by_category[cat_key][:transaction_count] += 1
        end
      end
    end

    transactions.sort_by! { |t| [ t[:date], t[:category_key].to_s, t[:vendor_name] ] }

    build_full_hash(transactions, summary_by_category)
  end

  def generate_and_write_csv(output_dir = nil, account_name: "Checking")
    output_dir ||= File.join(__dir__, "..", "tmp", "demo")
    FileUtils.mkdir_p(output_dir)

    data = generate
    transactions_path = File.join(output_dir, "demo_transactions.csv")
    summary_path = File.join(output_dir, "demo_summary.csv")
    import_path = File.join(output_dir, "demo_import.csv")

    write_transactions_csv(data[:transactions], transactions_path)
    write_summary_csv(data[:summary], summary_path)
    write_import_csv(data[:transactions], import_path, account_name: account_name)

    { transactions_path: transactions_path, summary_path: summary_path, import_path: import_path, data: data }
  end

  private

  def monthly_dates
    @monthly_dates ||= begin
      list = []
      d = start_date.beginning_of_month
      while d <= end_date
        list << d
        d = (d >> 1).beginning_of_month
      end
      list
    end
  end

  def compute_per_year_months
    result = {}
    DEMO_TEMPLATE.each do |cat_key, config|
      cadence = config[:cadence]
      next unless cadence.is_a?(Hash) && cadence[:per_year]

      n = cadence[:per_year]
      result[cat_key] = monthly_dates.sample(n, random: rng).to_set
    end
    result
  end

  def transaction_count_for(cadence, month_start, cat_key, per_year_months)
    return 0 unless cadence.is_a?(Hash)

    if cadence[:per_year]
      return 0 unless per_year_months[cat_key]&.include?(month_start)
      return 1
    end

    return 0 unless cadence[:per_month]

    per_month = cadence[:per_month]
    case per_month
    when Integer
      per_month
    when Array
      min, max = per_month
      rng.rand(min..max)
    else
      0
    end
  end

  def amounts_for_month(config, n, monthly_budget_cents, annual_budget_cents)
    cadence = config[:cadence]
    if cadence.is_a?(Hash) && cadence[:per_year]
      per_year = cadence[:per_year]
      amount_per = (annual_budget_cents / per_year).round
      return Array.new(n, amount_per)
    end

    if (variance = config[:amount_variance]) && variance > 0
      # Base amount per transaction = (monthly budget) / n; each amount ±variance (e.g. ±10%). No normalization.
      base = monthly_budget_cents.to_f / n
      return n.times.map { (base * (1 - variance + 2 * variance * rng.rand)).round }
    end

    split_with_variance(monthly_budget_cents, n)
  end

  def split_with_variance(total_cents, n)
    return [ total_cents ] if n <= 1

    weights = n.times.map { 0.7 + 0.6 * rng.rand }
    sum_w = weights.sum
    amounts = weights.map { |w| (total_cents * w / sum_w).round }
    diff = total_cents - amounts.sum
    amounts[0] += diff
    amounts
  end

  def pick_dates_in_month(month_start, month_end, n, category_key)
    if category_key == :rent || category_key == :income
      return [ month_start ] if n == 1
    end

    pool = (month_start..month_end).to_a
    pool.sample(n, random: rng)
  end

  def memo_for(category_key, vendor_name)
    ""
  end

  def build_full_hash(transactions, summary_by_category)
    categories = DEMO_TEMPLATE.map do |key, config|
      {
        key: key,
        category_name: config[:category_name],
        subcategory_name: config[:subcategory_name],
        target_pct: config[:pct],
        vendors: config[:vendors]
      }
    end

    vendors_flat = DEMO_TEMPLATE.flat_map do |key, config|
      config[:vendors].map { |name| { name: name, category_key: key } }
    end.uniq { |v| v[:name] }

    summary = summary_by_category.map do |cat_key, v|
      {
        category_key: cat_key,
        target_pct: v[:target_pct],
        target_annual_cents: v[:target_annual_cents],
        generated_annual_cents: v[:generated_annual_cents],
        transaction_count: v[:transaction_count]
      }
    end

    {
      meta: {
        annual_salary_dollars: annual_salary_dollars,
        salary_growth_rate: salary_growth_rate,
        take_home_ratio: take_home_ratio,
        start_date: start_date,
        end_date: end_date,
        seed: seed
      },
      budget: { name: "Demo Budget", currency: "USD" },
      categories: categories,
      accounts: [ { key: :checking, name: "Checking", on_budget: true } ],
      vendors: vendors_flat,
      transactions: transactions,
      summary: summary
    }
  end

  def write_transactions_csv(transactions, path)
    CSV.open(path, "w") do |csv|
      csv << %w[date period category subcategory vendor amount_cents amount_dollars memo]
      transactions.each do |t|
        period = t[:date].end_of_month
        csv << [
          t[:date].iso8601,
          period.iso8601,
          t[:category_name],
          t[:subcategory_name],
          t[:vendor_name],
          t[:amount_cents],
          "%.2f" % (t[:amount_cents] / 100.0),
          t[:memo]
        ]
      end
    end
  end

  def write_summary_csv(summary, path)
    CSV.open(path, "w") do |csv|
      csv << %w[category_key target_pct target_annual_cents generated_annual_cents transaction_count]
      summary.each do |row|
        csv << [
          row[:category_key],
          row[:target_pct],
          row[:target_annual_cents],
          row[:generated_annual_cents],
          row[:transaction_count]
        ]
      end
    end
  end

  # Writes a CSV in the format expected by the app's Import Transactions (TrxImportService):
  # Required: Date, Account, Vendor, Subcategory, Amount. Optional: Memo.
  # Use this file in the UI: Transactions → Import → choose demo_import.csv.
  # The budget must have an account matching account_name (e.g. "Checking") and default personal categories.
  def write_import_csv(transactions, path, account_name: "Checking")
    CSV.open(path, "w") do |csv|
      csv << %w[Date Account Vendor Subcategory Amount Memo]
      transactions.each do |t|
        csv << [
          t[:date].iso8601,
          account_name,
          t[:vendor_name],
          t[:subcategory_name],
          "%.2f" % (t[:amount_cents] / 100.0),
          t[:memo].to_s
        ]
      end
    end
  end
end

# Date#beginning_of_month / end_of_month (ActiveSupport). This file is pure Ruby; provide simple impl.
class Date
  def beginning_of_month
    Date.new(year, month, 1)
  end

  def end_of_month
    Date.new(year, month, -1)
  end
end

if __FILE__ == $PROGRAM_NAME
  end_date = Date.today
  start_date = end_date - (5 * 365)

  result = DemoDataGenerator.new(
    annual_salary_dollars: 80_000,
    start_date: start_date,
    end_date: end_date,
    salary_growth_rate: 0.03,
    seed: 42
  ).generate_and_write_csv

  puts "Wrote:"
  puts "  #{result[:transactions_path]}"
  puts "  #{result[:summary_path]}"
  puts "  #{result[:import_path]} (use in app: Transactions → Import)"
  puts "Transactions: #{result[:data][:transactions].size}"
end

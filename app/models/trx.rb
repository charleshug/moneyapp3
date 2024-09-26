class Trx < ApplicationRecord
  require "csv"

  validates :date, presence: true
  belongs_to :account
  belongs_to :vendor
  # belongs_to :subcategory
  # belongs_to :ledger
  # belongs_to :transfer, class_name: "Trx", optional: true
  # delegate :category, to: :subcategory
  has_many :lines, dependent: :destroy
  delegate :budget, to: :account
  accepts_nested_attributes_for :lines, allow_destroy: true

  scope :income, -> {
    joins(lines: { ledger: { subcategory: :category } })
    .where(categories: Category.income)
  }
  scope :expense, -> {
    joins(lines: { ledger: { subcategory: :category } })
    .where(categories: Category.expense)
  }

  scope :within_dates, ->(start_date, end_date) { where(date: start_date..end_date) }

  def self.ransackable_attributes(auth_object = nil)
    [ "account_id", "amount", "category_id", "subcategory_id", "cleared", "created_at", "date", "id", "id_value", "memo", "transfer_id", "updated_at", "vendor_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # note: these match belongs_to (no plurals)
    [ "account", "category", "subcategory", "vendor", "lines" ]
  end

  def self.to_csv
    attributes = %w[id date amount memo account_name category_name subcategory_name vendor_name]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.includes(:account, :category, :subcategory, :vendor).each do |trx|
        csv << [
          trx.id,
          trx.date,
          trx.amount.to_f / 100, # Convert amount back to decimal
          trx.memo,
          trx.account.name,
          trx.category.name,
          trx.subcategory.name,
          trx.vendor.name
        ]
      end
    end
  end

  def self.generate_report(start_date, end_date)
  # Get all budget categories
  categories = Category.all

  # Prepare an empty hash to store the report data
  report_data = {}

  # Loop through each category
  categories.each do |category|
    # Get transactions for the current category within the specified date range
    transactions = Trx.where(category_id: category.id)
                      .within_dates(start_date, end_date)
                      .group_by_month(:date, format: "%b %Y")
                      .sum(:amount)

    # Loop through each month within the date range
    (start_date..end_date).each do |date|
      # Format the date as month and year
      formatted_date = date.strftime("%b %Y")

      # If there are transactions for the current month, use the sum of amounts,
      # otherwise, set the amount to 0
      amount = transactions[formatted_date] || 0

      # Initialize the report data hash for the current category if not present
      report_data[category.name] ||= {}

      # Set the amount for the current month and category
      report_data[category.name][formatted_date] = amount
    end
  end

  # Return the report data
  report_data
end

  def self.get_sum_amount_by_date
    Trx.group("strftime('%Y-%m', date)").sum(:amount)
  end

  def self.get_income_in_month(date)
    Trx.income
       .where(date: date.beginning_of_month .. date.end_of_month)
       .sum(:amount)
  end

  def self.get_income_before_month(date)
    Trx.income
       .where(date: .. date.prev_month.end_of_month)
       .sum(:amount)
  end

  def self.get_income_in_date_range(start_date, end_date)
    Trx.income
       .where(date: start_date..end_date)
       .sum(:amount)
  end

  def self.get_expense_in_month(date)
    Trx.expense
       .where(date: date.beginning_of_month ..date.end_of_month)
       .sum(:amount)
  end

  def self.expenses
    joins(subcategory: :category)
      .where(categories: { normal_balance: "EXPENSE" })
  end

  def self.get_expense_before_month(date)
    Trx.expense
       .where(date: ..date.prev_month.end_of_month)
       .sum(:amount)
  end

  def self.get_hash_trx_by_category_all
    Category.left_joins(:trxes).group("categories.parent_id").sum(:amount)
  end

  def set_ledger
    ledger = budget.ledgers.find_or_create_by(date: date.end_of_month, subcategory: subcategory)
    self.ledger=ledger
  end
end

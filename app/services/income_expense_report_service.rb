# app/services/income_expense_report_service.rb

class IncomeExpenseReportService
  def initialize(current_budget, start_date, end_date)
    @current_budget = current_budget
    @start_date = start_date
    @end_date = end_date
  end

  def call
    # income_data = income_by_vendor_and_month
    income_data = @current_budget.lines
    .includes(trx: :vendor)
    .joins(ledger: { subcategory: :category })
    .where(trxes: { date: @start_date..@end_date })
    .where(categories: { normal_balance: "INCOME" })

    # expense_data = expenses_by_category_and_month
    expense_data = @current_budget.lines
                                .includes(ledger: { subcategory: :category })
                                .where(trxes: { date: @start_date..@end_date })
                                .where(categories: { normal_balance: "EXPENSE" })
    format_report_data(income_data, expense_data)
  end

  def format_report_data(income_data, expense_data)
    all_categories = @current_budget.categories.expense.includes(:subcategories)
    report_data = initialize_report_structure

    populate_income_data(report_data, income_data)
    populate_expense_data(report_data, expense_data, all_categories)
    report_data
  end

  private

  # def load_all_categories
  #   @current_budget.categories.expense.includes(:subcategories).each_with_object({}) do |category, hash|
  #     hash[category.name] = category.subcategories.map(&:name)
  #   end
  # end

  def initialize_report_structure
    {
      income: {},
      expenses: {},
      months: (@start_date..@end_date).map { |d| d.beginning_of_month }.uniq.map { |d| d.strftime("%Y-%m") }
    }
  end

  def populate_income_data(report_data, income_data)
    total_income = Hash.new(0)

    income_data.group_by { |line| line.trx.vendor }.each do |vendor, lines|
      report_data[:income][vendor.name] ||= {}

      lines.each do |line|
        month_key = line.trx.date.strftime("%Y-%m")
        report_data[:income][vendor.name][month_key] ||= 0
        report_data[:income][vendor.name][month_key] += line.amount
        total_income[month_key] += line.amount
      end
    end

    report_data[:income]["All Income Sources"] = total_income
  end

  def populate_expense_data(report_data, expense_data, all_categories)
    all_categories.each do |category|
      report_data[:expenses][category.name] ||= {}

      category.subcategories.each do |subcategory|
        report_data[:expenses][category.name][subcategory.name] ||= {}
      end
    end

    expense_data.joins(ledger: { subcategory: :category }).group_by(&:category).each do |category, categories|
      categories.group_by(&:subcategory).each do |subcategory, lines|
        lines.each do |line|
          month_key = line.trx.date.strftime("%Y-%m")
          report_data[:expenses][category.name] ||= {}
          report_data[:expenses][category.name][subcategory.name] ||= {}
          report_data[:expenses][category.name][subcategory.name][month_key] ||= 0

          report_data[:expenses][category.name][subcategory.name][month_key] += line.amount
        end
      end
    end
  end
end

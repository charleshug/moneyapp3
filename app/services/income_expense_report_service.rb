# app/services/income_expense_report_service.rb

class IncomeExpenseReportService
  def initialize(current_budget,start_date, end_date)
    @current_budget = current_budget
    @start_date = start_date
    @end_date = end_date
  end

  def call
    income_data = income_by_vendor_and_month
    expense_data = expenses_by_category_and_month
    format_report_data(income_data, expense_data)
  end

  private

  def income_by_vendor_and_month
    @current_budget.trxes.select("vendors.name AS vendor_name, TO_CHAR(trxes.date, 'YYYY-MM') AS month, SUM(trxes.amount) AS total_amount")
       .joins(:vendor, :category)
       .where("categories.parent_id = ?", 1)
       .where(trxes: { date: @start_date..@end_date })
       .group("vendors.name, month")
       .order("vendors.name, month")
  end

  def expenses_by_category_and_month
    @current_budget.trxes
       .select("parent_categories_trxes.name AS parent_name, categories.name AS category_name, TO_CHAR(trxes.date, 'YYYY-MM') AS month, SUM(trxes.amount) AS total_amount")
       .joins("INNER JOIN categories ON trxes.category_id = categories.id")
       .joins("INNER JOIN categories AS parent_categories_trxes ON categories.parent_id = parent_categories_trxes.id")
       .where("categories.parent_id IS NOT NULL")
       .merge(@current_budget.categories.expense)
       .where(trxes: { date: @start_date..@end_date })
       .group("parent_name, categories.name, month")
       .order("parent_name, categories.name, month")
  end

  def format_report_data(income_data, expense_data)
    # Fetch all parent categories and their subcategories from the database
    all_categories = @current_budget.categories.parent_category_expense.includes(:subcategories).each_with_object({}) do |parent_category, hash|
      hash[parent_category.name] = parent_category.subcategories.map(&:name)
    end

    report_data = {
      income: {},
      expenses: {},
      months: (@start_date..@end_date).map { |d| d.beginning_of_month }.uniq.map { |d| d.strftime("%Y-%m") }
    }

    total_income = Hash.new(0)
    income_data.group_by(&:vendor_name).each do |vendor_name, transactions|
      report_data[:income][vendor_name] = transactions.each_with_object({}) do |trx, hash|
        hash[trx.month] = trx.total_amount
        total_income[trx.month] += trx.total_amount
      end
    end

    # Add the "All Income Sources" row
    report_data[:income]["All Income Sources"] = total_income

    # Initialize the expenses section with all categories and subcategories
    all_categories.each do |parent_name, subcategories|
      report_data[:expenses][parent_name] ||= {}
      subcategories.each do |category_name|
        report_data[:expenses][parent_name][category_name] ||= {}
      end
    end

    # Populate the expenses section with actual data
    expense_data.group_by(&:parent_name).each do |parent_name, categories|
      report_data[:expenses][parent_name] ||= {}
      categories.group_by(&:category_name).each do |category_name, transactions|
        report_data[:expenses][parent_name][category_name] ||= {}
        transactions.each do |trx|
          report_data[:expenses][parent_name][category_name][trx.month] = trx.total_amount
        end
      end
    end

    report_data
  end


end

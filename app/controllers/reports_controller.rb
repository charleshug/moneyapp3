class ReportsController < ApplicationController
  before_action :set_spending_by_params, only: [ :spending_by_vendor, :spending_by_category ]

  def spending_by_category
    @q = @current_budget.trxes.includes(:account, :subcategory, :vendor).ransack(params[:q])
    @trxes = @q.result(distinct: true).merge(@current_budget.categories.expense).order(date: :desc)

    @output = SpendingByCategoryReportService.get_hash_trx_by_category_1(@trxes)
  end

  def net_worth
    @q = @current_budget.trxes.includes(:account, :subcategory, :vendor).ransack(params[:q])
    @trxes = @q.result(distinct: true).order(date: :asc)

    @output = NetWorthReportService.get_hash_net_worth(@trxes)
  end

  def spending_by_vendor
    @q = @current_budget.trxes.includes(:account, :subcategory, :vendor).ransack(params[:q])
    @trxes = @q.result(distinct: true)
    .joins(subcategory: :category)  # Join through subcategory to category
    .where(categories: { normal_balance: "EXPENSE" })  # Filter for expense categories
    .order(date: :desc)  # Order transactions by date
    @output = SpendingByVendorReportService.get_hash_trx_by_vendor_cat(@trxes)
  end


  def income_expense
    @start_date = parse_date(params[:start_date], Date.today.beginning_of_year)
    @end_date = parse_date(params[:end_date], Date.today.end_of_year)

    @report_data = IncomeExpenseReportService.new(@current_budget, @start_date, @end_date).call
  end

  private

  def parse_date(date_string, default)
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    default
  end

  def set_spending_by_params
    income_category_ids = @current_budget.categories.income.ids
    # income_parent_category_ids = @current_budget.categories.parent_category_income.ids
    default_params = { category_id_not_in: income_category_ids }

    # @ransack_params = permitted_params.reverse_merge(default_params)
    @ransack_params = params.fetch(:q, {}).permit(
      account_id_in: [],
      category_id_in: [],
      subcategory_id_in: [],
      vendor_id_in: [],
      date_gteq: [],
      date_lteq: []
    ).reverse_merge(default_params)
  end
end

# Shared logic for budget index table data (display months, summary by month, table data).
# Used by BudgetsController#index and by LedgersController when refreshing the budget table via Turbo Stream.
module BudgetIndexData
  extend ActiveSupport::Concern

  def set_budget_index_data(selected_month)
    @selected_month = selected_month.is_a?(Date) ? selected_month : Date.parse(selected_month.to_s)
    @display_months = [
      @selected_month.months_ago(2).end_of_month,
      @selected_month.months_ago(1).end_of_month,
      @selected_month,
      @selected_month.next_month.end_of_month
    ]
    @selected_month_index = @display_months.index(@selected_month) || 2
    @budget_table_data_by_month = @display_months.map { |month| BudgetService.generate_budget_table_data(@current_budget, month) }
    @budget_table_data = @budget_table_data_by_month[@selected_month_index]
    @summary_by_month = @display_months.map do |month|
      prev = month.prev_month
      {
        budget_available_previously: BudgetService.get_budget_available(@current_budget, prev.end_of_month),
        overspent_prev: @current_budget.ledgers.get_overspent_in_date_range(prev.beginning_of_month, prev.end_of_month),
        income_current: @current_budget.lines.income.joins(:trx).where(trxes: { date: month.beginning_of_month..month.end_of_month }).sum(:amount),
        budget_current: @current_budget.ledgers.get_budget_sum_current_month(month),
        budget_available_current: BudgetService.get_budget_available(@current_budget, month)
      }
    end
  end
end

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

    # Batch all summary queries (3 + 1 + 1 + 1 = 6 queries instead of 4 * 6 = 24)
    prev_month_ends = @display_months.map { |m| m.prev_month.end_of_month }.uniq
    all_budget_available_dates = (@display_months + prev_month_ends).uniq
    budget_available_by_date = BudgetService.get_budget_available_for_dates(@current_budget, all_budget_available_dates)
    overspent_by_date = Ledger.get_overspent_by_dates(@current_budget.ledgers, prev_month_ends)
    income_by_month = Line.income_sum_by_month_end_dates(@current_budget.lines, @display_months)
    budget_sum_by_month = Ledger.get_budget_sum_by_dates(@current_budget.ledgers, @display_months)

    @summary_by_month = @display_months.map do |month|
      prev = month.prev_month
      prev_end = prev.end_of_month
      {
        budget_available_previously: budget_available_by_date[prev_end].to_d,
        overspent_prev: overspent_by_date[prev_end].to_d,
        income_current: income_by_month[month].to_d,
        budget_current: budget_sum_by_month[month].to_d,
        budget_available_current: budget_available_by_date[month].to_d
      }
    end
  end
end

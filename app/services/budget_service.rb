class BudgetService
  def self.get_budget_available(current_budget, date)
    date = date.end_of_month

    overspent_prev = current_budget.ledgers.get_overspent_before_month(date.prev_month.end_of_month)
    income_prev = current_budget.trxes.get_income_before_month(date)
    budget_prev = current_budget.ledgers.get_budget_sum_before_month(date)
    budget_available_previously = overspent_prev + income_prev - budget_prev

    overspent_current = current_budget.ledgers.get_overspent_in_date_range(date.prev_month.beginning_of_month, date.prev_month.end_of_month)
    income_current = current_budget.trxes.get_income_in_month(date)
    budget_current = current_budget.ledgers.get_budget_sum_current_month(date)
    budget_available_previously + overspent_current + income_current - budget_current
  end

  def self.generate_budget_table_data(current_budget, selected_month)
    categories = current_budget.categories.expense
    ledgers = current_budget.ledgers.includes(:category).where(date: selected_month)

    budget_table_data = []

    current_budget.categories.parent_category_expense.each do |parent|
      parent_ledgers = ledgers.select { |l| l.category.parent_id == parent.id }
      parent_budget = parent_ledgers.sum(&:budget)
      parent_actual = parent_ledgers.sum(&:actual)
      parent_balance = 0

      parent_data = {
        name: parent.name,
        budget: parent_budget,
        actual: parent_actual,
        balance: parent_balance,
        subcategories: []
      }

      categories.where(parent_id: parent.id).each do |category|
        ledger = ledgers.detect { |l| l.category_id == category.id }
        subcategory_data = if ledger
                             {
                               id: category.id,
                               name: category.name,
                               budget: ledger.budget,
                               actual: ledger.actual,
                               balance: ledger.balance,
                               ledger: ledger
                             }
        else
                             previous_ledger = Ledger.where(category_id: category.id).where("date < ?", selected_month).order(date: :desc).first
                             balance_to_display = previous_ledger&.carry_forward_negative_balance ? previous_ledger.balance : [ previous_ledger.balance, 0 ].max if previous_ledger
                             {
                               id: category.id,
                               name: category.name,
                               budget: 0,
                               actual: 0,
                               balance: previous_ledger ? balance_to_display : 0,
                               ledger: nil
                             }
        end

        parent_balance += subcategory_data[:balance]
        parent_data[:subcategories] << subcategory_data
      end

      parent_data[:balance] = parent_balance
      budget_table_data << parent_data
    end

    budget_table_data
  end
end

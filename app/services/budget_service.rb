class BudgetService
  def self.get_budget_available(current_budget, date)
    date = date.end_of_month

    overspent_prev = current_budget.ledgers.get_overspent_before_month(date.prev_month.end_of_month)
    income_prev = current_budget.lines.income.joins(:trx).where("trxes.date < ?", date).sum(:amount)

    budget_prev = current_budget.ledgers.get_budget_sum_before_month(date)
    budget_available_previously = overspent_prev + income_prev - budget_prev

    overspent_current = current_budget.ledgers.get_overspent_in_date_range(date.prev_month.beginning_of_month, date.prev_month.end_of_month)
    income_ledgers = current_budget.ledgers.where(date: date.end_of_month, subcategory: Subcategory.find_by(category: Category.find_by(name: "Income Parent")))
    income_current = income_ledgers.sum(:actual)
    budget_current = current_budget.ledgers.get_budget_sum_current_month(date)
    budget_available_previously + overspent_current + income_current - budget_current
  end


  def self.generate_budget_table_data(current_budget, selected_month)
    categories = current_budget.categories.expense
    ledgers = current_budget.ledgers.includes(:subcategory).where(date: selected_month)

    budget_table_data = []

    # Iterate through each category
    categories.each do |category|
      parent_budget = 0
      parent_actual = 0
      parent_balance = 0

      parent_data = {
        id: category.id,
        name: category.name,
        budget: 0,
        actual: 0,
        balance: 0,
        subcategories: []
      }

      # Iterate through the subcategories of the current category
      category.subcategories.each do |subcategory|
        # Get the ledger associated with the subcategory for the selected month (if it exists)
        ledger = ledgers.detect { |l| l.subcategory_id == subcategory.id }

        subcategory_data = if ledger
                            {
                              id: subcategory.id,
                              name: subcategory.name,
                              budget: ledger.budget,
                              actual: ledger.actual,
                              balance: ledger.balance,
                              ledger: ledger
                            }
        else
                            # If no ledger exists for the selected month, check for previous ledgers
                            previous_ledger = Ledger.where(subcategory_id: subcategory.id).where("date < ?", selected_month).order(date: :desc).first
                            balance_to_display = previous_ledger&.carry_forward_negative_balance ? previous_ledger.balance : [ previous_ledger.balance, 0 ].max if previous_ledger
                            {
                              id: subcategory.id,
                              name: subcategory.name,
                              budget: 0,
                              actual: 0,
                              balance: previous_ledger ? balance_to_display : 0,
                              ledger: nil
                            }
        end

        # Accumulate subcategory totals into the parent category
        parent_budget += subcategory_data[:budget]
        parent_actual += subcategory_data[:actual]
        parent_balance += subcategory_data[:balance]

        # Add the subcategory data to the parent
        parent_data[:subcategories] << subcategory_data
      end

      # Populate the parent category data with the summed totals from its subcategories
      parent_data[:budget] = parent_budget
      parent_data[:actual] = parent_actual
      parent_data[:balance] = parent_balance

      # Add the parent data to the budget table data
      budget_table_data << parent_data
    end

    budget_table_data
  end
end

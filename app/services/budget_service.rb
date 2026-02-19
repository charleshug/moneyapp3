class BudgetService
  def self.get_budget_available(current_budget, date)
    date = date.end_of_month

    overspent = current_budget.ledgers
      .joins(subcategory: :category)
      .where("ledgers.date < ?", date.beginning_of_month)
      .where(categories: { normal_balance: "EXPENSE" })
      .where(carry_forward_negative_balance: false)
      .sum(:balance)

    income = current_budget.ledgers
      .joins(subcategory: :category)
      .where("ledgers.date <= ?", date)
      .where(categories: { normal_balance: "INCOME" })
      .sum(:actual)

    budgeted = current_budget.ledgers
      .joins(subcategory: :category)
      .where("ledgers.date <= ?", date)
      .where(categories: { normal_balance: "EXPENSE" })
      .sum(:budget)

    overspent + income - budgeted
  end


  def self.generate_budget_table_data(current_budget, selected_month)
    # Eager load all related data in a single query
    categories = current_budget.categories.expense
      .includes(:subcategories)
      .includes(subcategories: :ledgers)
      .order(:name)  # Order categories alphabetically

    end_of_month = selected_month.end_of_month.to_date

    categories.map do |category|
      # Order subcategories alphabetically within each category
      subcategories_data = category.subcategories.order(:name).map do |subcategory|
        current_ledger = subcategory.ledgers.find_by(date: end_of_month)
        previous_ledger = current_ledger&.prev
        if previous_ledger.nil?
          previous_ledger = subcategory.ledgers.where("date < ?", end_of_month).order(date: :desc).first
        end

        # Determine balance based on ledger availability
        balance = 0
        carry_forward = false
        if current_ledger
                    balance = current_ledger.balance
                    carry_forward = current_ledger.carry_forward_negative_balance
        elsif previous_ledger
                    balance = previous_ledger.rolling_balance
                    carry_forward = previous_ledger.carry_forward_negative_balance
        end

        {
          id: subcategory.id,
          name: subcategory.name,
          budget: current_ledger&.budget || 0,
          actual: current_ledger&.actual || 0,
          balance: balance,
          carry_forward: carry_forward,
          previous_amount: previous_ledger&.budget || 0, # previous_ledger is nil if it's the first ledger
          ledger: current_ledger
        }
      end

      # Calculate category totals
      category_budget = subcategories_data.sum { |s| s[:budget] }
      category_actual = subcategories_data.sum { |s| s[:actual] }

      {
        id: category.id,
        name: category.name,
        budget: category_budget,
        actual: category_actual,
        balance: subcategories_data.sum { |s| s[:balance] },
        subcategories: subcategories_data
      }
    end
  end
end

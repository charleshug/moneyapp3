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
    categories = current_budget.categories.expense
      .includes(:subcategories)
      .order(:name)

    end_of_month = selected_month.end_of_month.to_date
    subcategory_ids = categories.flat_map { |c| c.subcategories.map(&:id) }

    # Batch load current-month ledgers with prev to avoid N+1
    current_ledgers_by_sub = Ledger
      .where(subcategory_id: subcategory_ids, date: end_of_month)
      .includes(:prev)
      .index_by(&:subcategory_id)

    # Batch load latest ledger before end_of_month per subcategory (for rows with no current ledger)
    previous_ledgers_by_sub = Ledger
      .where(subcategory_id: subcategory_ids)
      .where("date < ?", end_of_month)
      .order(:subcategory_id, date: :desc)
      .to_a
      .group_by(&:subcategory_id)
      .transform_values(&:first)

    categories.map do |category|
      subcategories_data = category.subcategories.sort_by(&:name).map do |subcategory|
        current_ledger = current_ledgers_by_sub[subcategory.id]
        previous_ledger = current_ledger&.prev || previous_ledgers_by_sub[subcategory.id]

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
          previous_amount: previous_ledger&.budget || 0,
          ledger: current_ledger
        }
      end

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

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

  # Returns Hash[Date => Numeric] for many dates in 3 queries instead of 3*N.
  def self.get_budget_available_for_dates(current_budget, dates)
    dates = dates.map { |d| d.respond_to?(:end_of_month) ? d.end_of_month : d }.uniq
    return {} if dates.empty?

    max_date = dates.max
    # Use Ledger + category scope to avoid Subcategory default_scope (ORDER BY subcategories.order) which conflicts with GROUP BY
    base = Ledger.joins(subcategory: :category).where(categories: { budget_id: current_budget.id })

    # Overspent as of beginning of each month: balance where date < month start, expense, no carry forward
    expense_balance_by_date = base
      .where(categories: { normal_balance: "EXPENSE" })
      .where(carry_forward_negative_balance: false)
      .where("ledgers.date < ?", max_date.beginning_of_month)
      .group(:date)
      .sum(:balance)

    # Income and budgeted cumulative to each month
    income_by_date = base
      .where(categories: { normal_balance: "INCOME" })
      .where("ledgers.date <= ?", max_date)
      .group(:date)
      .sum(:actual)

    budgeted_by_date = base
      .where(categories: { normal_balance: "EXPENSE" })
      .where("ledgers.date <= ?", max_date)
      .group(:date)
      .sum(:budget)

    dates.index_with do |date|
      month_start = date.beginning_of_month
      overspent = expense_balance_by_date.select { |ledger_date, _| ledger_date < month_start }.sum { |_, v| v }
      income = income_by_date.select { |ledger_date, _| ledger_date <= date }.sum { |_, v| v }
      budgeted = budgeted_by_date.select { |ledger_date, _| ledger_date <= date }.sum { |_, v| v }
      overspent + income - budgeted
    end
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
      subcategories_data = category.subcategories.map do |subcategory|
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

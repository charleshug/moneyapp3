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
    # Eager load all related data in a single query
    categories = current_budget.categories.expense
      .includes(:subcategories)
      .includes(subcategories: :ledgers)

    end_of_month = selected_month.end_of_month.to_date

    categories.map do |category|
      subcategories_data = category.subcategories.map do |subcategory|
        # More explicit ledger matching
        current_ledger = subcategory.ledgers.find_by(date: end_of_month)
        previous_ledger = current_ledger&.prev
        if previous_ledger.nil?
          previous_ledger = subcategory.ledgers.where("date < ?", end_of_month).order(date: :desc).first
        end

        # Determine balance based on ledger availability
        balance = if current_ledger
                    current_ledger.balance
        elsif previous_ledger
                    previous_ledger.balance
        else
                    0
        end

        Rails.logger.debug "Subcategory: #{subcategory.name}"
        Rails.logger.debug "Current ledger: #{current_ledger.inspect}"
        Rails.logger.debug "Previous ledger: #{previous_ledger.inspect}"

        {
          id: subcategory.id,
          name: subcategory.name,
          budget: current_ledger&.budget || 0,
          actual: current_ledger&.actual || 0,
          balance: balance,
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

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_current_budget

  private
  def set_current_budget
    if current_user.budgets.empty?
      redirect_to new_budget_path, notice: "Please create a budget first."
      return
    end

    budget_id = session[:last_viewed_budget_id]
    budget = Budget.find_by(id: budget_id)

    if budget && current_user.budgets.include?(budget)
      @current_budget = budget
    else
      update_current_budget
    end
  end

  def update_current_budget
    if current_user.last_viewed_budget_id.present?
      current_budget = Budget.find_by(id: current_user.last_viewed_budget_id)

      if current_budget && current_user.budgets.include?(current_budget)
        # current_budget belongs to the current_user
        @current_budget = current_budget
      else
        use_fallback_budget
      end
    else
      # last_viewed_budget_id is blank
      use_fallback_budget
    end
  end


  def use_fallback_budget
    if current_user.budgets.any?
      puts "DEBUG: FALLBACK A"
      first_budget = current_user.budgets.first
      current_user.update(last_viewed_budget_id: first_budget.id)
      session[:last_viewed_budget_id] = first_budget.id
      @current_budget = first_budget
    else
      puts "DEBUG: FALLBACK B"
      # Handle case where the user has no budgets
      redirect_to new_budget_path, notice: "Please create a budget first."
    end
  end
end

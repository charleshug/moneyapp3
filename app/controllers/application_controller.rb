class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_current_budget

  private
  def set_current_budget
    return unless current_user

    if current_user.budgets.empty?
      redirect_to new_budget_path, notice: "Please create a budget first."
      return
    end

    @current_budget = find_budget_from_user ||
                     find_budget_from_session ||
                     use_first_budget
  end

  def find_budget_from_session
    return nil unless session[:last_viewed_budget_id]

    budget = current_user.budgets.find_by(id: session[:last_viewed_budget_id])
    if budget
      unless current_user.last_viewed_budget_id == budget.id
        current_user.update_column(:last_viewed_budget_id, budget.id)
      end
    else
      session.delete(:last_viewed_budget_id)
    end
    budget
  end

  def find_budget_from_user
    return nil unless current_user.last_viewed_budget_id

    budget = current_user.budgets.find_by(id: current_user.last_viewed_budget_id)
    if budget
      session[:last_viewed_budget_id] = budget.id
    else
      current_user.update_column(:last_viewed_budget_id, nil)
    end
    budget
  end

  def use_first_budget
    budget = current_user.budgets.first
    if budget
      session[:last_viewed_budget_id] = budget.id
      current_user.update_column(:last_viewed_budget_id, budget.id)
    end
    budget
  end
end

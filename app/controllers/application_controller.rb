class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_current_budget

  private
  def set_current_budget
    Rails.logger.info "=== Setting Current Budget ==="
    Rails.logger.info "User: #{current_user.email}"
    Rails.logger.info "Session budget_id: #{session[:last_viewed_budget_id]}"
    Rails.logger.info "User's last_viewed_budget_id: #{current_user.last_viewed_budget_id}"

    return unless current_user

    if current_user.budgets.empty?
      Rails.logger.info "No budgets found for user"
      redirect_to new_budget_path, notice: "Please create a budget first."
      return
    end

    @current_budget = find_budget_from_user ||
                     find_budget_from_session ||
                     use_first_budget

    Rails.logger.info "Final selected budget: #{@current_budget.name} (ID: #{@current_budget.id})"
    Rails.logger.info "=== End Setting Current Budget ==="
  end

  def find_budget_from_session
    return nil unless session[:last_viewed_budget_id]

    Rails.logger.info "Attempting to find budget from session ID: #{session[:last_viewed_budget_id]}"
    budget = current_user.budgets.find_by(id: session[:last_viewed_budget_id])

    if budget
      Rails.logger.info "Found budget from session: #{budget.name} (ID: #{budget.id})"
      unless current_user.last_viewed_budget_id == budget.id
        Rails.logger.info "Updating user's last_viewed_budget_id to match session"
        current_user.update_column(:last_viewed_budget_id, budget.id)
      end
    else
      Rails.logger.info "Session budget not found, clearing session"
      session.delete(:last_viewed_budget_id)
    end
    budget
  end

  def find_budget_from_user
    return nil unless current_user.last_viewed_budget_id

    Rails.logger.info "Attempting to find budget from user's last_viewed_budget_id: #{current_user.last_viewed_budget_id}"
    budget = current_user.budgets.find_by(id: current_user.last_viewed_budget_id)

    if budget
      Rails.logger.info "Found budget from user: #{budget.name} (ID: #{budget.id})"
      Rails.logger.info "Updating session to match user's budget"
      session[:last_viewed_budget_id] = budget.id
    else
      Rails.logger.info "User's last viewed budget not found, clearing user's last_viewed_budget_id"
      current_user.update_column(:last_viewed_budget_id, nil)
    end
    budget
  end

  def use_first_budget
    budget = current_user.budgets.first
    if budget
      Rails.logger.info "Using first budget as fallback: #{budget.name} (ID: #{budget.id})"
      session[:last_viewed_budget_id] = budget.id
      current_user.update_column(:last_viewed_budget_id, budget.id)
    else
      Rails.logger.info "No first budget found"
    end
    budget
  end
end

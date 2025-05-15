class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_current_budget
  before_action :load_accounts_for_sidebar

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

  def load_accounts_for_sidebar
    # Set default empty values
    @sidebar_accounts = []
    @sidebar_on_budget_accounts = []
    @sidebar_off_budget_accounts = []
    @sidebar_closed_accounts = []
    @sidebar_total_balance = 0
    @sidebar_on_budget_balance = 0
    @sidebar_off_budget_balance = 0
    @sidebar_closed_balance = 0

    return unless @current_budget

    @sidebar_accounts = @current_budget.accounts.to_a
    @sidebar_on_budget_accounts = @sidebar_accounts.select { |a| a.on_budget && !a.closed }.sort_by(&:name)
    @sidebar_off_budget_accounts = @sidebar_accounts.select { |a| !a.on_budget && !a.closed }.sort_by(&:name)
    @sidebar_closed_accounts = @sidebar_accounts.select { |a| a.closed }.sort_by(&:name)

    @sidebar_total_balance = @sidebar_accounts.sum(&:balance)
    @sidebar_on_budget_balance = @sidebar_on_budget_accounts.sum(&:balance)
    @sidebar_off_budget_balance = @sidebar_off_budget_accounts.sum(&:balance)
    @sidebar_closed_balance = @sidebar_closed_accounts.sum(&:balance)
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

class BudgetsController < ApplicationController
  skip_before_action :set_current_budget, only: [ :new, :create ]
  before_action :set_budget, only: %i[ edit update destroy ]

  def set_current
    @budget = Budget.find(params[:id])
    if @budget.user == current_user
      current_user.set_current_budget(@budget)
      session[:last_viewed_budget_id] = @budget.id
      flash[:notice] = "Current budget has been updated."
    else
      flash[:alert] = "You are not authorized to set this budget as current."
    end
    redirect_to root_path
  end

  def index
    set_selected_month_from_params

    @budget_available_previously = BudgetService.get_budget_available(@current_budget, @selected_month.prev_month.end_of_month)
    @overspent_prev = @current_budget.ledgers.get_overspent_in_date_range(@selected_month.prev_month.beginning_of_month, @selected_month.prev_month.end_of_month)
    @income_current = @current_budget.lines.income.joins(:trx).where(trxes: { date: @selected_month.beginning_of_month..@selected_month.end_of_month }).sum(:amount)
    @budget_current = @current_budget.ledgers.get_budget_sum_current_month(@selected_month)
    @budget_available_current = BudgetService.get_budget_available(@current_budget, @selected_month)
    @budget_table_data = BudgetService.generate_budget_table_data(@current_budget, @selected_month)
  end

  def new
    @budget = current_user.budgets.new
  end

  def create
    @budget = current_user.budgets.build(budget_params)

    if @budget.save
      # Update both session and user's last viewed budget
      session[:last_viewed_budget_id] = @budget.id
      current_user.update(last_viewed_budget_id: @budget.id)

      redirect_to root_path, notice: "Budget was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @budget.update(budget_params)
        format.html { redirect_to budget_url(@budget), notice: "Budget was successfully updated." }
        format.json { render :show, status: :ok, location: @budget }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @budget.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @budget.user.update(last_viewed_budget_id: nil)
    @budget.destroy!
    current_user.set_current_budget

    respond_to do |format|
      format.html { redirect_to budgets_url, notice: "Budget was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def update_budgets
    date = Date.parse(params[:date])

    case params[:option]
    when "Zero all budgeted amounts"
      LedgerService.zero_all_budgeted_amounts(@current_budget, date)
    when "Budget values used last month"
      LedgerService.budget_values_used_last_month(@current_budget, date)
    when "Last month outflows"
      LedgerService.last_month_outflows(@current_budget, date)
    when "Balance to zero"
      LedgerService.balance_to_zero(@current_budget, date)
    end

    redirect_to budgets_path, notice: "Budget values have been updated."
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_budget
    @budget = Budget.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def budget_params
    params.require(:budget).permit(:name, :description, :budget_type)
  end

  def set_selected_month_from_params
    if params[:date].present?
      year = params[:date][:year].to_i.zero? ? Date.today.year : params[:date][:year].to_i
      month = params[:date][:month].to_i.zero? ? Date.today.month : params[:date][:month].to_i
      @selected_month = Date.new(year, month, 1).end_of_month
      session[:selected_month] = @selected_month
    elsif session[:selected_month].present?
      @selected_month = Date.parse(session[:selected_month])
    else
      @selected_month = Date.today.end_of_month
      session[:selected_month] = @selected_month.to_s
    end
  end
end

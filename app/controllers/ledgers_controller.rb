class LedgersController < ApplicationController
  before_action :set_ledger, only: %i[ edit update ]

  def index
    @q = @current_budget.ledgers.includes(:subcategory).ransack(params[:q])
    @ledgers = @q.result(distinct: true).order(date: :desc)

    # @ledgers = Ledger.order(subcategory_id: :asc, date: :asc)
  end

  def new
    @ledger = Ledger.new(ledger_params)
  end

    def create
      @ledger = LedgerService.new.create_ledger(ledger_params)
      respond_to do |format|
        if @ledger.valid?
          format.html { redirect_to budgets_path(year: @ledger.date.year, month: @ledger.date.month), notice: "Ledger was successfully created." }

        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

  def edit
    # Ensure the ledger belongs to the current budget
    if @ledger.subcategory.budget != @current_budget
      redirect_to ledgers_path, alert: "You are not authorized to edit this ledger."
      nil
    end
  end

  def update
    # Ensure the ledger belongs to the current budget
    if @ledger.subcategory.budget != @current_budget
      redirect_to ledgers_path, alert: "You are not authorized to edit this ledger."
      return
    end

    @ledger = LedgerService.new.update_ledger(@ledger, ledger_update_params)
    respond_to do |format|
      if @ledger.valid?
        format.html { redirect_to budgets_path(year: @ledger.date.year, month: @ledger.date.month), notice: "Ledger was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_ledger
    @ledger = Ledger.find(params[:id])
  end

  def ledger_params
    params.require(:ledger).permit(:id, :budget, :date, :subcategory_id, :carry_forward_negative_balance)
  end

  def ledger_update_params
    params.fetch(:ledger, {}).permit(:id, :budget, :carry_forward_negative_balance)
  end
end

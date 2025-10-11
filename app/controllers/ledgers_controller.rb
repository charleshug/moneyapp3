class LedgersController < ApplicationController
  include Pagy::Backend

  before_action :set_ledger, only: %i[ edit update ]

  def index
    @current_budget = Budget.includes(:categories, subcategories: :category)
                           .find(@current_budget.id)

    # Load collections for filter dropdowns - eager load subcategories with their categories
    @categories = @current_budget.categories.includes(:subcategories).order(:name)

    # No need to load subcategories separately as they're included with categories

    # Build the base query with proper joins and includes
    base_query = @current_budget.ledgers
                               .select("ledgers.*, subcategories.name as subcategory_name, categories.name as category_name")
                               .joins(subcategory: :category)
                               .includes(subcategory: :category)

    @q = base_query.ransack(params[:q])

    # Use Ransack's sort or fall back to default sort
    @q.sorts = [ "date desc", "id desc" ] if @q.sorts.empty?

    # Get filtered count with a more efficient query
    @filtered_count = @q.result.count(:id)

    # Get paginated results
    @pagy, @ledgers = pagy(@q.result(distinct: true))
  end

  def rebuild_chains
    subcategory_ids = @current_budget.subcategories.pluck(:id)
    subcategory_ids.each do |subcategory_id|
      Ledger.rebuild_chain_for_subcategory(subcategory_id)
    end

    # Redirect back to the same page with the same filters
    redirect_to ledgers_path(
      q: {
        date_gteq: params.dig(:q, :date_gteq),
        date_lteq: params.dig(:q, :date_lteq),
        s: params.dig(:q, :s),
        subcategory_category_id_in: params.dig(:q, :subcategory_category_id_in),
        subcategory_id_in: params.dig(:q, :subcategory_id_in)
      }.compact_blank,
      page: params[:page]
    ), notice: "Ledger chains have been rebuilt."
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
    if LedgerService.update(@ledger, ledger_params)
      redirect_to budgets_path(year: @ledger.date.year, month: @ledger.date.month), notice: "Ledger was successfully created."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_carry_forward
    @ledger = Ledger.find(params[:id])
    @ledger.toggle_carry_forward_and_propagate!

    # Redirect back to the same page with the same filters
    redirect_to ledgers_path(
      q: {
        date_gteq: params.dig(:q, :date_gteq),
        date_lteq: params.dig(:q, :date_lteq),
        s: params.dig(:q, :s),
        subcategory_category_id_in: params.dig(:q, :subcategory_category_id_in),
        subcategory_id_in: params.dig(:q, :subcategory_id_in)
      }.compact_blank,
      page: params[:page]
    ), notice: "Ledger carry forward setting updated."
  end

  def update_budget
    @ledger = Ledger.find(params[:id])

    # Ensure the ledger belongs to the current budget
    if @ledger.subcategory.budget != @current_budget
      render json: { error: "You are not authorized to edit this ledger." }, status: :unauthorized
      return
    end

    budget_amount = params[:budget].to_f

    if LedgerService.update(@ledger, budget: budget_amount)
      render json: {
        success: true,
        budget: number_to_currency(budget_amount),
        balance: number_to_currency(@ledger.rolling_balance / 100.0)
      }
    else
      render json: {
        success: false,
        errors: @ledger.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def create_budget
    subcategory_id = params[:subcategory_id]
    date = Date.parse(params[:date])
    budget_amount = params[:budget].to_f

    # Ensure the subcategory belongs to the current budget
    subcategory = Subcategory.find(subcategory_id)
    if subcategory.budget != @current_budget
      render json: { error: "You are not authorized to create this ledger." }, status: :unauthorized
      return
    end

    ledger_params = {
      subcategory_id: subcategory_id,
      date: date,
      budget: budget_amount
    }

    @ledger = LedgerService.new.create_ledger(ledger_params)

    if @ledger.valid?
      render json: {
        success: true,
        ledger_id: @ledger.id,
        budget: number_to_currency(budget_amount),
        balance: number_to_currency(@ledger.rolling_balance / 100.0)
      }
    else
      render json: {
        success: false,
        errors: @ledger.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private
  def set_ledger
    @ledger = Ledger.find(params[:id])
  end

  def ledger_params
    params.require(:ledger).permit(:subcategory_id, :date, :budget, :carry_forward_negative_balance)
  end

  def ledger_update_params
    params.fetch(:ledger, {}).permit(:id, :budget, :carry_forward_negative_balance)
  end

  def filter_params
    return {} unless params[:q]

    {
      date_gteq: params[:q][:date_gteq],
      date_lteq: params[:q][:date_lteq],
      s: params[:q][:s],
      subcategory_category_id_in: params[:q][:subcategory_category_id_in],
      subcategory_id_in: params[:q][:subcategory_id_in]
    }.compact_blank
  end
end

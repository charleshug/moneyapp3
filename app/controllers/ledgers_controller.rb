class LedgersController < ApplicationController
  include Pagy::Backend

  before_action :set_ledger, only: %i[ edit update ]

  def index
    @current_budget = Budget.includes(:categories, subcategories: :category)
                           .find(@current_budget.id)

    # Load collections for filter dropdowns
    @categories = @current_budget.categories.order(:name)
    @subcategories = @current_budget.subcategories.order(:name)

    base_query = @current_budget.ledgers
                               .select("ledgers.*, subcategories.name as subcategory_name, categories.name as category_name")
                               .joins(subcategory: :category)
                               .includes(subcategory: :category)

    @q = base_query.ransack(params[:q])

    # Use Ransack's sort or fall back to default sort
    @q.sorts = [ "date desc", "id desc" ] if @q.sorts.empty?

    # Get filtered results and paginate
    @filtered_results = @q.result
    @filtered_count = @filtered_results.count("DISTINCT ledgers.id")

    # Get paginated results
    @pagy, @ledgers = pagy(@filtered_results)
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
    service = LedgerService.new(@ledger)

    if service.update(ledger_params)
      redirect_to ledgers_path, notice: "Ledger was successfully updated."
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

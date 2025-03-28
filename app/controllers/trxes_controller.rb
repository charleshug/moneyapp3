class TrxesController < ApplicationController
  include Pagy::Backend
  before_action :set_trx, only: %i[ edit update destroy ]
  before_action :check_transfer_child, only: %i[ update destroy ]

  def index
    @current_budget = Budget.includes(:accounts, :vendors, :categories, subcategories: :category)
                           .find(@current_budget.id)

    # Load collections for filter dropdowns
    @accounts = @current_budget.accounts.order(:name)
    @vendors = @current_budget.vendors.order("LOWER(name)")
    @categories = @current_budget.categories
    @subcategories = @current_budget.subcategories

    base_query = @current_budget.trxes
                               .select("trxes.*, accounts.name as account_name, vendors.name as vendor_name")
                               .joins(:account, :vendor)
                               .includes(:account, :vendor, lines: { ledger: { subcategory: :category } })

    @q = base_query.ransack(params[:q])

    # Use Ransack's sort or fall back to default sort
    @q.sorts = [ "date desc", "id desc" ] if @q.sorts.empty?

    # Get filtered results and paginate
    @filtered_results = @q.result
    @filtered_count = @filtered_results.count("DISTINCT trxes.id")

    # Get paginated results
    @pagy, @trxes = pagy(@filtered_results)
  end

  # GET /trxes/new
  def new
    @trx = Trx.new
    @trx.lines.build
  end

  # GET /trxes/1/edit
  def edit
    # Ensure the record belongs to the current budget
    if @trx.budget != @current_budget
      redirect_to trxes_path, alert: "You are not authorized to edit this transaction."
      nil
    end

    # Render a different template for transfer child transactions
    if @trx.transfer_child?
      render "show_transfer_child"
    end
    # If not a transfer child, it will render the default 'edit' template

    @trx.lines.each do |line|
      line.subcategory_form_id = line.ledger.subcategory_id
    end
  end

  # POST /trxes or /trxes.json
  def create
    @trx = TrxCreatorService.new(@current_budget, trx_params).create_trx

    respond_to do |format|
      if @trx.valid?
        format.html { redirect_to trxes_path(q: { account_id_in: @trx.account.id }), notice: "Trx was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trxes/1 or /trxes/1.json
  def update
    # Ensure the record belongs to the current budget
    if @trx.budget != @current_budget
      redirect_to trxes_path, alert: "You are not authorized to edit this transaction."
      return
    end

    @trx = TrxEditingService.new(@trx, trx_params).edit_trx
    respond_to do |format|
      if @trx.valid?
        format.html { redirect_to edit_trx_path(@trx), notice: "Trx was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trxes/1 or /trxes/1.json
  def destroy
    # Ensure the record belongs to the current budget
    if @trx.budget != @current_budget
      redirect_to trxes_path, alert: "You are not authorized to edit this transaction."
      return
    end

    trx_delete_service = TrxDeleteService.new(@trx)
    trx_delete_service.delete_trx

    respond_to do |format|
      format.html { redirect_to trxes_path(q: { account_id_in: @trx.account.id }), notice: "Trx was successfully destroyed." }
    end
  end

  def add_line_to_trx
    @trx = Trx.find(params[:id])
    @line = @trx.lines.build
    @line.subcategory_form_id = nil

    respond_to do |format|
      format.turbo_stream
    end
  end

  def add_line_to_new_trx
    @trx = Trx.new
    @line = @trx.lines.build
    @line.subcategory_form_id = nil

    respond_to do |format|
      format.turbo_stream
    end
  end

  def import
    # Any setup needed for the import form
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trx
      @trx = Trx.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def trx_params
      params.require(:trx).permit(
        :account_id,
        :vendor_id,
        :vendor_custom_text,
        :date,
        :memo,
        :cleared,
        lines_attributes: [
          :id,
          :ledger_id,
          :subcategory_form_id,
          :amount,
          :memo,
          :transfer_account_id,
          :_destroy
        ]
      )
    end

  def convert_amount_to_cents(amount)
    (amount.to_d * 100).to_i
  end

  def ransack_params
    params.require(:q).permit(
      :date_gteq, :date_lteq,
      account_id_in: [],
      vendor_id_in: [],
      lines_ledger_subcategory_category_id_in: [],
      lines_ledger_subcategory_id_in: []
    )
  end

  # Check if the transaction is a transfer child and redirect if necessary
  def check_transfer_child
    if @trx.transfer_child?
      parent_trx = @trx.parent_transaction
      if parent_trx
        redirect_to edit_trx_path(parent_trx), alert: "This is a transfer transaction. Please make changes to the original transaction instead."
      else
        redirect_to trxes_path, alert: "This is a transfer transaction and cannot be modified directly."
      end
      false
    end
  end
end

class TrxesController < ApplicationController
  include Pagy::Backend
  before_action :set_trx, only: %i[ edit update destroy ]

  def index
    @current_budget_trxes = @current_budget.trxes
    @q = @current_budget_trxes.includes(:account, :vendor, lines: [ ledger: [ subcategory: :category ] ]).ransack(params[:q])
    @pagy, @trxes = pagy(@q.result(distinct: true).order(date: :desc), items: 25)

    @total_trx_count = @q.result(distinct: true).count
    @total_trx_sum = @q.result(distinct: true).sum(:amount)
    @displayed_trx_count = @trxes.count
    @displayed_trx_sum = @trxes.sum(:amount)
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
    @trx.lines.each do |line|
      line.subcategory_form_id = line.ledger.subcategory_id
    end
  end

  # POST /trxes or /trxes.json
  def create
    @trx = @current_budget.trxes.build
    @trx = TrxCreatorService.new.create_trx(@current_budget, trx_params)

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

    @trx = TrxEditingService.new.edit_trx(@trx, trx_params)
    respond_to do |format|
      if @trx.valid?
        format.html { redirect_to trxes_path(q: { account_id_in: @trx.account.id }), notice: "Trx was successfully updated." }
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

  # def import
  #   @parsed_trxes = TrxImportService.parse(params[:file], @current_budget)

  #   if @parsed_trxes
  #     session[:parsed_trxes] = @parsed_trxes
  #     redirect_to import_review_trxes_path
  #   else
  #     redirect_to accounts_path, alert: "Error in CSV file."
  #   end
  # end

  # def import_review
  #   @categories = @current_budget.categories.includes(:subcategories)
  #   @accounts = @current_budget.accounts
  #   @trxes = session[:parsed_trxes]
  #   if @trxes.nil?
  #     redirect_to new_trx_path, alert: "No trxes to import"
  #   end
  # end

  # def submit_import
  #   ledgers_to_update = Set.new
  #   accounts_to_update = Set.new

  #   imported_trxes = params[:trx][:trxes].values.select { |trx| trx["include"] == "1" }

  #   if imported_trxes.empty?
  #     redirect_to new_trx_path, notice: "No transactions selected for import" and return
  #   end
  #   ActiveRecord::Base.transaction do
  #     imported_trxes.each do |trx_params|
  #       trx = @current_budget.trxes.build(
  #         date: trx_params["date"],
  #         account_id: trx_params["account_id"],
  #         vendor_id: trx_params["vendor_id"],
  #         memo: trx_params["memo"]
  #       )

  #       trx_params["lines_attributes"].each do |_, line_params|
  #         line = trx.lines.build(
  #           subcategory_form_id: line_params["subcategory_id"],
  #           amount: convert_amount_to_cents(line_params["amount"])
  #         )
  #         line.set_ledger
  #         ledgers_to_update << line.ledger
  #       end


  #       trx.set_amount
  #       trx.save!
  #       accounts_to_update << trx.account
  #       trx.lines.each { |line| ledgers_to_update << line.ledger }
  #     end

  #     accounts_to_update.each { |account| account.calculate_balance! }
  #     ledgers_to_update.each { |ledger| LedgerService.new.recalculate_forward_ledgers(ledger) }
  #   end

  #   redirect_to trxes_path, notice: "Transactions imported successfully."
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trx
      @trx = Trx.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def trx_params
      params.fetch(:trx, {}).permit(
        :id, :date, :memo, :amount, :subcategory_id, :account_id, :vendor_id, :vendor_custom_text,
        :cleared, :trxes, :q, lines_attributes: [ :id, :subcategory_form_id, :ledger_id, :amount, :_destroy ]
        )
    end

  def convert_amount_to_cents(amount)
    (amount.to_d * 100).to_i
  end
end

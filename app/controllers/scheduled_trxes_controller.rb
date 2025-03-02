class ScheduledTrxesController < ApplicationController
  before_action :set_scheduled_trx, only: [ :edit, :update, :destroy ]

  def index
    @scheduled_trxes = @current_budget.scheduled_trxes.where(active: true)
  end

  def new
    @scheduled_trx = @current_budget.scheduled_trxes.build
    @scheduled_trx.scheduled_lines.build
  end

  def edit
  end

  def create
    @scheduled_trx = ScheduledTrxCreatorService.new.create_trx(@current_budget, scheduled_trx_params)

    if @scheduled_trx.valid?
      redirect_to scheduled_trxes_path, notice: "Scheduled transaction was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @scheduled_trx.budget != @current_budget
      redirect_to scheduled_trxes_path, alert: "You are not authorized to edit this transaction."
      return
    end

    @scheduled_trx = ScheduledTrxEditingService.new.edit_trx(@scheduled_trx, scheduled_trx_params)

    if @scheduled_trx.valid?
      redirect_to scheduled_trxes_path, notice: "Scheduled transaction was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create_selected
    selected_ids = params[:selected_ids] || []
    ActiveRecord::Base.transaction do
      selected_ids.each do |id|
        scheduled_trx = ScheduledTrx.find(id)
        scheduled_trx.create_trx!
      end
    end

    redirect_to scheduled_trxes_path, notice: "Selected transactions have been created."
  end

  def destroy
    @scheduled_trx.update!(active: false)
    redirect_to scheduled_trxes_path, notice: "Scheduled transaction was deleted."
  end

  def add_scheduled_line_to_scheduled_trx
    @scheduled_trx = ScheduledTrx.find(params[:id])
    @scheduled_line = @scheduled_trx.scheduled_lines.build
    @scheduled_line.subcategory_form_id = nil

    respond_to do |format|
      format.turbo_stream
    end
  end

  def add_scheduled_line_to_new_scheduled_trx
    @scheduled_trx = ScheduledTrx.new
    @scheduled_line = @scheduled_trx.scheduled_lines.build
    # @scheduled_line.subcategory_form_id = nil

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_scheduled_trx
    @scheduled_trx = @current_budget.scheduled_trxes.find(params[:id])
  end

  def scheduled_trx_params
    params.require(:scheduled_trx).permit(
      :account_id, :vendor_id, :next_date, :frequency, :memo,
      scheduled_lines_attributes: [ :id, :subcategory_id, :amount, :memo, :transfer_account_id, :_destroy ]
    )
  end
end

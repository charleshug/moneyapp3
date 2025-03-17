class TrxCreatorService
  attr_reader :budget, :trx_params, :trx

  def initialize(budget, trx_params)
    @budget = budget
    @trx_params = trx_params.dup
    @trx = nil
  end

  def create_trx
    ActiveRecord::Base.transaction do
      convert_amount_to_cents
      handle_vendor_custom_text

      @trx = @budget.trxes.build(@trx_params)
      set_ledger
      set_amount
      @trx.save
      update_ledgers_and_account if @trx.valid?
      @trx.lines.each do |line|
        if line.transfer_account_id.present?
          transfer_trx = TransferService.new(line).process
          line.update_column(:transfer_line_id, transfer_trx.lines.first.id)
        end
      end

      @trx
    end
  end

  private

  def update_ledgers_and_account
    ledgers_to_update = Set.new
    @trx.lines.each { |line| ledgers_to_update << line.ledger }

    ledgers_to_update.each do |ledger|
      LedgerService.recalculate_forward_ledgers(ledger)
    end

    @trx.account.calculate_balance! if @trx.account.present?
  end

  def handle_vendor_custom_text
    unless @trx_params[:vendor_custom_text].blank?
      vendor = @budget.vendors.find_or_create_by(name: @trx_params[:vendor_custom_text])
      @trx_params[:vendor_id] = vendor.id
    end
    @trx_params.delete(:vendor_custom_text)
  end

  def set_ledger
    @trx.lines.each do |line|
      subcategory_id = line.subcategory_form_id.presence || line.subcategory
      subcategory = @budget.subcategories.find(subcategory_id)

      ledger = Ledger.find_or_create_by(
        date: @trx.date.end_of_month,
        subcategory: subcategory
      )
      line.ledger = ledger
    end
  end

  def set_amount
    @trx.amount = @trx.lines.sum(&:amount)
  end

  def convert_amount_to_cents
    return unless @trx_params[:lines_attributes].present?

    @trx_params[:lines_attributes].each do |_, line_params|
      next unless line_params[:amount].present?

      line_params[:amount] = (line_params[:amount].to_d * 100).to_i
    end
  end
end

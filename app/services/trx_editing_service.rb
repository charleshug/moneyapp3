class TrxEditingService
  def initialize(trx, trx_params)
    @trx = trx
    @trx_params = trx_params.dup
    @ledgers_to_update = Set.new
    @accounts_to_update = Set.new
  end

  def edit_trx
    ActiveRecord::Base.transaction do
      convert_amount_to_cents
      handle_vendor_custom_text
      save_trx_state

      update_trx_state
      @trx.save
      unless @trx.valid?
        # trx failed, do something
      end

      save_trx_state
      update_impacted_ledgers_and_accounts

      @trx
    end
  end

  def update_trx_state
    @trx.assign_attributes(@trx_params)
    set_ledger
    set_amount
  end

  def save_trx_state
    save_impacted_ledgers
    save_impacted_accounts
  end

  def update_impacted_ledgers_and_accounts
    update_impacted_ledgers
    update_impacted_accounts
  end

  def update_impacted_accounts
    @accounts_to_update.each do |account|
      account.calculate_balance!
    end
  end

  def save_impacted_accounts
    @trx.lines.each { |line| @accounts_to_update << line.account }
  end

  def update_impacted_ledgers
    @ledgers_to_update.each do |ledger|
      LedgerService.recalculate_forward_ledgers(ledger)
    end
  end

  def set_amount
    @trx.amount = @trx.lines.sum(&:amount)
  end

  def save_impacted_ledgers
    @trx.lines.each { |line| @ledgers_to_update << line.ledger }
  end

  def set_ledger
    @trx.lines.each do |line|
      subcategory = if line.subcategory_form_id.present?
        @trx.budget.subcategories.find(line.subcategory_form_id)
      else
        line.ledger&.subcategory
      end

      next unless subcategory  # Skip if no subcategory found

      ledger = @trx.budget.ledgers.find_or_create_by(
        date: @trx.date.end_of_month,
        subcategory: subcategory
      )
      line.ledger = ledger
    end
  end

  def handle_vendor_custom_text
    unless @trx_params[:vendor_custom_text].blank?
      vendor = @budget.vendors.find_or_create_by(name: @trx_params[:vendor_custom_text])
      @trx_params[:vendor_id] = vendor.id
    end
    @trx_params.delete(:vendor_custom_text)
  end

  def convert_amount_to_cents
    return unless @trx_params[:lines_attributes].present?

    @trx_params[:lines_attributes].each do |_, line_params|  # Keep index key (_ ignored)
      if line_params[:amount].present?
        line_params[:amount] = (line_params[:amount].to_d * 100).to_i
      end
    end
  end
end

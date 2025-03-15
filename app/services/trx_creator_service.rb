class TrxCreatorService
  def create_trx(budget, trx_params)
    ActiveRecord::Base.transaction do
      convert_amount_to_cents(trx_params)

      unless trx_params[:vendor_custom_text].blank?
        vendor = budget.vendors.find_or_create_by(name: trx_params[:vendor_custom_text])
        trx_params[:vendor_id] = vendor.id
      end
      trx_params.delete(:vendor_custom_text)

      trx = budget.trxes.build(trx_params)
      set_ledger(trx)
      trx.set_amount
      trx.save

      # Only proceed with updates if the transaction is valid
      if trx.valid?
        ledgers_to_update = Set.new
        trx.lines.each { |line| ledgers_to_update << line.ledger }
        ledgers_to_update.each do |ledger|
          LedgerService.recalculate_forward_ledgers(ledger)
        end

        trx.account.calculate_balance! if trx.account.present?
      end

      trx
    end
  end

  private

  def set_ledger(trx)
    trx.lines.each do |line|
      subcategory_id = line.subcategory_form_id.presence || line.subcategory

      ledger = Ledger.find_or_create_by(
        date: trx.date.end_of_month,
        subcategory: Subcategory.find(subcategory_id)
      )
      line.ledger = ledger
    end
  end

  def set_amount(trx)
    trx.amount = trx.lines.sum(:amount)
  end

  def convert_amount_to_cents(trx_params)
    return unless trx_params[:lines_attributes].present?

    trx_params[:lines_attributes].each do |_, line_params|  # Keep index key (_ ignored)
      if line_params[:amount].present?
        line_params[:amount] = (line_params[:amount].to_d * 100).to_i
      end
    end
  end
end

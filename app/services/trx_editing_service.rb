class TrxEditingService
  def edit_trx(trx, trx_params)
    ActiveRecord::Base.transaction do
      convert_amount_to_cents(trx_params)

      unless trx_params[:vendor_custom_text].empty?
        vendor = trx.budget.vendors.find_or_create_by(name: trx_params[:vendor_custom_text])
        trx_params[:vendor_id] = vendor.id
      end
      trx_params.delete(:vendor_custom_text)

      ledgers_to_update = Set.new

      trx.lines.each { |line| ledgers_to_update << line.ledger }
      trx.assign_attributes(trx_params)

      set_ledger(trx)
      trx.set_amount

      trx.save
      if trx.invalid?
        # trx failed, do something
      end

      trx.lines.each { |line| ledgers_to_update << line.ledger }

      ledgers_to_update.each do |ledger|
        LedgerService.new.recalculate_forward_ledgers(ledger)
      end
      trx.account.calculate_balance!

      trx
    end
  end

  def set_ledger(trx)
    trx.lines.each do |line|
      subcategory = line.subcategory_form_id || line.ledger.subcategory
      ledger = Ledger.find_or_create_by(date: trx.date.end_of_month, subcategory: subcategory)
      line.ledger=ledger
    end
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

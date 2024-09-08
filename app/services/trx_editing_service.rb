class TrxEditingService

  def edit_trx(trx, trx_params)
    convert_amount_to_cents(trx_params)
    ledgers_to_update = Set.new
    ledgers_to_update.add(trx.ledger)

    if trx.transfer_id?
      
      if trx_params[:vendor_id] && Vendor.find(trx_params[:vendor_id]).account.nil?
        #transfer becomes non-transfer
        old_account = trx.transfer.account
        ledgers_to_update.add(trx.transfer.ledger)
        trx.transfer.delete
        old_account.calculate_balance!

        #update remaining params like non-transfer
        trx.transfer_id = nil
        trx.assign_attributes(trx_params)
        set_ledger(trx)
        trx.save!

        if trx.invalid?
          #do something
          return trx
        end
        ledgers_to_update.add(trx.ledger)
      
      else
        #transfer remains a transfer
        trx.assign_attributes(trx_params)
        set_ledger(trx)
        trx.save!
        if trx.invalid?
          return trx
        end
        edit_opposite_trx(trx)
        trx.transfer.account.calculate_balance!
        ledgers_to_update.add(trx.ledger)
        ledgers_to_update.add(trx.transfer.ledger)

      end

    elsif trx_params[:vendor_id] && !Vendor.find(trx_params[:vendor_id]).account.nil?
      #non-transfer become transfer
      trx.update(trx_params)
      if trx.invalid?
        #trx failed, do something
        
      end
      transfer_trx = create_opposite_trx(trx)
      trx.update(transfer: transfer_trx)
      ledgers_to_update.add(trx.ledger)
      ledgers_to_update.add(trx.transfer.ledger)
      transfer_trx.account.calculate_balance!
      trx.account.calculate_balance!

    else
      #non-transfer trx
      trx.assign_attributes(trx_params)
      set_ledger(trx)
      trx.save
      #trx.update(trx_params)
      if trx.invalid?
        #trx failed, do something
        
      end
      ledgers_to_update.add(trx.ledger)
      trx.account.calculate_balance!

    end
    ledgers_to_update.each do |ledger|
      LedgerService.new.recalculate_forward_ledgers(ledger)
    end
    trx
  end


  def edit_opposite_trx(trx)
    transfer_trx = trx.transfer
    attributes = {
      date: trx.date,
      amount: -trx.amount,
      vendor_id: trx.account.vendor.id,
      account_id: trx.vendor.account.id,
      subcategory_id: trx.subcategory_id,
      ledger_id: trx.ledger_id,
      memo: trx.memo,
    }
    transfer_trx.assign_attributes(attributes)
    set_ledger(transfer_trx)
    transfer_trx.save!

  end

    def create_opposite_trx(trx)
    attributes = {
      date: trx.date,
      amount: -trx.amount,
      vendor_id: trx.account.vendor.id,
      account_id: trx.vendor.account.id,
      subcategory_id: trx.subcategory_id,
      transfer_id: trx.id,
      memo: trx.memo,
    }
    opposite_trx = Trx.new(attributes)
    set_ledger(opposite_trx)
    opposite_trx.save!
    opposite_trx
  end

  def set_ledger(trx)
    ledger = Ledger.find_or_create_by(date:trx.date.end_of_month, subcategory: trx.subcategory )
    trx.ledger=ledger
  end

  def convert_amount_to_cents(trx_params)
    trx_params[:amount] = (trx_params[:amount].to_d * 100).to_i if trx_params[:amount]
  end
end
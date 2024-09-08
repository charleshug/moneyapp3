class TrxCreatorService

  def create_trx(trx)
    set_ledger(trx)
    trx.save
    if trx.invalid?
      #do something when trx fails
      return trx
    end

    trx.account.calculate_balance!
    LedgerService.new.update_ledger_from_trx(trx)

    #if trx is a transfer
    unless trx.vendor.account.nil?
      transfer_trx = create_opposite_trx(trx)
      trx.update_column(:transfer_id, transfer_trx.id)
      transfer_trx.account.calculate_balance!
      LedgerService.new.update_ledger_from_trx(transfer_trx)
    end

    trx
  end

  def set_ledger(trx)
    ledger = Ledger.find_or_create_by(date:trx.date.end_of_month, subcategory: trx.subcategory )
    trx.ledger=ledger
  end

  def create_opposite_trx(trx)
    attributes = {
      date: trx.date,
      amount: -trx.amount,
      vendor_id: trx.account.vendor.id,
      account_id: trx.vendor.account.id,
      subcategory_id: trx.subcategory_id,
      ledger_id: trx.ledger_id, #note: when using on/off budgets this will need to change as transfer trx could have different category than trx
      transfer_id: trx.id,
      memo: trx.memo,
    }
    Trx.create!(attributes)
  end

end
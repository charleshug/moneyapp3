class TrxCreatorService
  def create_trx(trx)
    set_ledger(trx)
    # trx.amount = trx.lines.sum(:amount)
    trx.amount = trx.lines.sum { |line| line.amount } # necessary when not yet saved to the database
    trx.save
    if trx.invalid?
      # do something when trx fails
      return trx
    end

    trx.account.calculate_balance!
    # LedgerService.new.update_ledger_from_trx(trx)
    trx.lines.each do |line|
      LedgerService.new.update_ledger_from_line(line)
    end

    # # if trx is a transfer
    # unless trx.vendor.account.nil?
    #   transfer_trx = create_opposite_trx(trx)
    #   trx.update_column(:transfer_id, transfer_trx.id)
    #   transfer_trx.account.calculate_balance!
    #   LedgerService.new.update_ledger_from_trx(transfer_trx)
    # end

    # TODO - update to search in lines.transfer_id
    # if trx is a transfer
    unless trx.vendor.account.nil?
      transfer_trx = create_opposite_trx(trx)
      trx.lines.first.update_column(:transfer_line_id, transfer_trx.lines.first.id)
      transfer_trx.account.calculate_balance!
      LedgerService.new.update_ledger_from_line(transfer_trx.lines.first)
    end

    trx
  end

  def set_ledger(trx)
    # ledger = Ledger.find_or_create_by(date:trx.date.end_of_month, subcategory: trx.subcategory )
    # trx.ledger=ledger
    trx.lines.each do |line|
      if line.subcategory_form_id.empty?
        ledger = Ledger.find_or_create_by(date: trx.date.end_of_month, subcategory: Subcategory.find(line.subcategory))
      else
        # this line is being created or changed by a form
        ledger = Ledger.find_or_create_by(date: trx.date.end_of_month, subcategory: Subcategory.find(line.subcategory_form_id))
      end
      line.ledger=ledger
      debugger
    end
  end

  def create_opposite_trx(trx)
    # attributes = {
    #   date: trx.date,
    #   amount: -trx.amount,
    #   vendor_id: trx.account.vendor.id,
    #   account_id: trx.vendor.account.id,
    #   subcategory_id: trx.subcategory_id,
    #   ledger_id: trx.ledger_id, # note: when using on/off budgets this will need to change as transfer trx could have different category than trx
    #   transfer_id: trx.id,
    #   memo: trx.memo
    # }
    # Trx.create!(attributes)

    attributes = {
      date: trx.date,
      amount: -trx.amount,
      vendor_id: trx.account.vendor.id,
      account_id: trx.vendor.account.id,
      memo: trx.memo
    }
    opposite_trx = Trx.build(attributes)
    trx.lines.each do |line|
      opposite_trx.lines.build(
        amount: -line.amount,
        ledger_id: line.ledger_id,
        transfer_line_id: line.id,
        memo: line.memo
      )
    end
  end
end

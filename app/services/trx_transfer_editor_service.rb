class TrxTransferEditorService

  def editor_trx_transfer(trx)
    trx.save
    if trx.invalid?
      #do something when trx fails
      return trx
    end

    edit_opposite_trx(trx)

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
      memo: trx.memo,
    }
    transfer_trx.update!(attributes)
  end

end
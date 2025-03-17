class TransferService
  attr_reader :line

  def initialize(line)
    @line = line
  end

  def process
    # ensure the transfer account exists
    transfer_account = line.budget.accounts.find_by(id: line.transfer_account_id)
    return unless transfer_account

    create_transfer_trx(line)
  end

  private

  def create_transfer_trx(line)
    transfer_trx_params = {
      account_id: line.transfer_account_id,
      vendor_id: line.trx.account.vendor.id,
      date: line.trx.date,
      amount: -line.amount,
      memo: line.trx.memo,
      lines_attributes: [ {
        ledger_id: line.ledger_id,
        amount: -line.amount,
        transfer_line_id: line.id
      } ]
    }
    trx = line.budget.trxes.build(transfer_trx_params)

    trx.save!
    trx
  end
end

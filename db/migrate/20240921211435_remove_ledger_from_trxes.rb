class RemoveLedgerFromTrxes < ActiveRecord::Migration[7.2]
  def change
    remove_reference :trxes, :ledger
  end
end

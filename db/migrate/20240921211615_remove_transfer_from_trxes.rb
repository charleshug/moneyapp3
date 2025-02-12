class RemoveTransferFromTrxes < ActiveRecord::Migration[7.2]
  def change
    remove_reference :trxes, :transfer
  end
end

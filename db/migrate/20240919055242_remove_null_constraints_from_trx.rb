class RemoveNullConstraintsFromTrx < ActiveRecord::Migration[7.2]
  def change
    change_column_null :trxes, :subcategory_id, true
    change_column_null :trxes, :ledger_id, true
  end
end

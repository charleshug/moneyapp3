class AddRollingBalanceToLedger < ActiveRecord::Migration[7.2]
  def change
    add_column :ledgers, :rolling_balance, :integer, null: false, default: 0
  end
end

class CreateTrxes < ActiveRecord::Migration[7.2]
  def change
    create_table :trxes do |t|
      t.date :date, null: false
      t.integer :amount, null: false, default: 0
      t.string :memo
      t.references :account, null: false, foreign_key: true
      t.references :subcategory, null: false, foreign_key: true
      t.references :vendor, null: false, foreign_key: true
      t.references :ledger, null: false
      t.boolean :cleared, null: false, default: false
      t.integer :transfer_id

      t.timestamps
    end
  end
end

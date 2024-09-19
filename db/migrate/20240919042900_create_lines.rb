class CreateLines < ActiveRecord::Migration[7.2]
  def change
    create_table :lines do |t|
      t.integer :amount
      t.string :memo
      t.references :ledger, null: false, foreign_key: true
      t.references :trx, null: false, foreign_key: true
      t.references :transfer_line, foreign_key: { to_table: :lines }

      t.timestamps
    end
  end
end

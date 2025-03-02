class CreateScheduledTrxes < ActiveRecord::Migration[7.1]
  def change
    create_table :scheduled_trxes do |t|
      t.integer :amount, default: 0, null: false
      t.references :account, null: false, foreign_key: true
      t.references :vendor, foreign_key: true
      t.date :next_date, null: false
      t.string :frequency, null: false
      t.string :memo
      t.boolean :active, default: true

      t.timestamps
    end

    create_table :scheduled_lines do |t|
      t.references :scheduled_trx, null: false, foreign_key: true
      t.references :subcategory, null: false, foreign_key: true
      t.integer :amount, null: false
      t.string :memo
      t.references :transfer_account, foreign_key: { to_table: :accounts }

      t.timestamps
    end
  end
end

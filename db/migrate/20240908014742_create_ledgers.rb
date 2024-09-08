class CreateLedgers < ActiveRecord::Migration[7.2]
  def change
    create_table :ledgers do |t|
      t.date :date, null: false
      t.integer :budget, null: false, default: 0
      t.integer :actual, null: false, default: 0
      t.integer :balance, null: false, default: 0
      t.boolean :carry_forward_negative_balance, null: false, default: false
      t.boolean :user_changed, null: false, default: false
      t.references :subcategory, null: false, foreign_key: true
      t.references :next, foreign_key: { to_table: :ledgers }
      t.references :prev, foreign_key: { to_table: :ledgers }

      t.timestamps
    end

    add_index :ledgers, [ :date, :subcategory_id ], unique: true,
      comment: "One ledger per date/category"
  end
end

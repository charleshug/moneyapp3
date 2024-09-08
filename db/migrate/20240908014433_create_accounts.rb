class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.integer :balance, null: false, default: 0
      t.boolean :on_budget, null: false, default: true
      t.boolean :closed, null: false, default: false
      t.references :budget, null: false, foreign_key: true

      t.timestamps
    end
  end
end

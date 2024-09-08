class CreateBudgets < ActiveRecord::Migration[7.2]
  def change
    create_table :budgets do |t|
      t.string :name, null: false
      t.string :description
      t.string :currency
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :budgets, [ :user_id, :name ], unique: true
  end
end

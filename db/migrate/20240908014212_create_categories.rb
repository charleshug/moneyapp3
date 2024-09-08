class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.boolean :hidden, null: false, default: false
      t.string :normal_balance, null: false, default: "EXPENSE"
      t.references :budget, null: false, foreign_key: true

      t.timestamps
    end
  end
end

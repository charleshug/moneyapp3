class CreateVendors < ActiveRecord::Migration[7.2]
  def change
    create_table :vendors do |t|
      t.string :name, null: false
      t.references :budget, null: false, foreign_key: true
      t.references :account, foreign_key: true

      t.timestamps
    end
  end
end

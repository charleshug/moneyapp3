class CreateBudgetImportBatches < ActiveRecord::Migration[7.2]
  def change
    create_table :budget_import_batches do |t|
      t.references :budget, null: false, foreign_key: true
      t.text :parsed_ledgers

      t.timestamps
    end
  end
end

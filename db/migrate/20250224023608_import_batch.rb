class ImportBatch < ActiveRecord::Migration[7.2]
  def change
    create_table :import_batches do |t|
      t.references :budget, null: false, foreign_key: true
      t.json :parsed_trxes, null: false
      t.timestamps
    end

    add_index :import_batches, :created_at
  end
end

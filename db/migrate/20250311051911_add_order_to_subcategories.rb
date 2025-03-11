class AddOrderToSubcategories < ActiveRecord::Migration[7.2]
  def up
    add_column :subcategories, :order, :integer

    # Set initial order values for existing subcategories
    execute <<-SQL
      UPDATE subcategories s
      SET "order" = subquery.row_number
      FROM (
        SELECT id, category_id, ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY created_at) as row_number
        FROM subcategories
      ) AS subquery
      WHERE s.id = subquery.id
    SQL

    # Make the column non-nullable after setting values
    change_column_null :subcategories, :order, false

    add_index :subcategories, [ :category_id, :order ], unique: true
  end

  def down
    remove_index :subcategories, [ :category_id, :order ]
    remove_column :subcategories, :order
  end
end

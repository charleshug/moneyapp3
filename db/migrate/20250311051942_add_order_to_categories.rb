class AddOrderToCategories < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:categories, :order)
      add_column :categories, :order, :integer

      # Set initial order values for existing categories
      execute <<-SQL
        UPDATE categories c
        SET "order" = subquery.row_number
        FROM (
          SELECT id, budget_id, ROW_NUMBER() OVER (PARTITION BY budget_id ORDER BY created_at) as row_number
          FROM categories
        ) AS subquery
        WHERE c.id = subquery.id
      SQL

      # Make the column non-nullable after setting values
      change_column_null :categories, :order, false

      add_index :categories, [ :budget_id, :order ], unique: true
    end
  end

  # def down
  #   remove_index :categories, [ :budget_id, :order ]
  #   remove_column :categories, :order
  # end
end

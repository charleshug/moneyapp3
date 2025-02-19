class AddDefaultAmountToLine < ActiveRecord::Migration[7.2]
  def up
    # Set a default value for existing records with NULL amount
    execute "UPDATE lines SET amount = 0 WHERE amount IS NULL"

    # Change column to NOT NULL
    change_column_null :lines, :amount, false

    # Set default value for future inserts
    change_column_default :lines, :amount, 0
  end

  def down
    # Revert changes
    change_column_null :lines, :amount, true
    change_column_default :lines, :amount, nil
  end
end

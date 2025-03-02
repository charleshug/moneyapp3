class AddDefaultAmountToScheduledLinesAmount < ActiveRecord::Migration[7.2]
  def change
    change_column_default :scheduled_lines, :amount, 0
  end
end

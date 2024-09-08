class AddLastViewedBudgetToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :last_viewed_budget_id, :integer
  end
end

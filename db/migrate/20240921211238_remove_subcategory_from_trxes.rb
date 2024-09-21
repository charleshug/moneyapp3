class RemoveSubcategoryFromTrxes < ActiveRecord::Migration[7.2]
  def change
    remove_reference :trxes, :subcategory, null: false, foreign_key: true
  end
end

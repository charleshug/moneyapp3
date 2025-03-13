class Subcategory < ApplicationRecord
  include RailsSortable::Model
  set_sortable :order

  belongs_to :category
  has_many :ledgers, dependent: :destroy
  has_many :lines, through: :ledgers
  # has_many :trxes, through: :ledgers
  has_one :budget, through: :category

  validates :name, presence: true
  validates :order, uniqueness: { scope: :category_id }

  # Add default ordering with table name
  default_scope { order("subcategories.order") }

  def self.ransackable_attributes(auth_object = nil)
    [ "name" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # note: these match belongs_to (no plurals)
    [ "category", "lines", "ledgers", "name" ]
  end

  def full_name
    "#{category.name}: #{name}"
  end

  # Add a method to initialize order values if needed
  def self.initialize_orders(category_id)
    where(category_id: category_id).order(:created_at).each_with_index do |subcategory, index|
      subcategory.update_column(:order, index + 1) if subcategory.order.nil?
    end
  end
end

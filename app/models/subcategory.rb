class Subcategory < ApplicationRecord
  belongs_to :category
  has_many :ledgers, dependent: :destroy
  has_many :lines, through: :ledgers
  # has_many :trxes, through: :ledgers
  has_one :budget, through: :category

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [ "category_id", "name" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # note: these match belongs_to (no plurals)
    [ "category", "lines", "ledgers", "name" ]
  end

  def full_name
    "#{category.name}: #{name}"
  end
end

class Subcategory < ApplicationRecord
  belongs_to :category
  has_many :ledgers
  has_many :lines, through: :ledgers
  # has_many :trxes, through: :ledgers

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [ "category_id", "name" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # note: these match belongs_to (no plurals)
    [ "category", "lines", "ledgers", "name" ]
  end
end

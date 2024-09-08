class Vendor < ApplicationRecord
  belongs_to :budget
  belongs_to :account, optional: true
  validates :name, presence: true
  has_many :trxes

  scope :transfer, -> { where.not(account: nil) }
  scope :not_transfer, -> { where(account: nil) }

  def self.ransackable_attributes(auth_object = nil)
    [ "name" ]
  end

  DEFAULT_VENDORS = [ "Starting Balance", "Other", "Manual Balance Adjustment" ]
end

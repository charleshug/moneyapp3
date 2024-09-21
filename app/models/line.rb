class Line < ApplicationRecord
  belongs_to :trx
  belongs_to :ledger
  # has_one :subcategory, through: :ledger
  delegate :subcategory, to: :ledger
  delegate :category, to: :subcategory
  delegate :vendor, to: :trx
  delegate :date, to: :trx
  belongs_to :transfer_line, class_name: "Line", optional: true
  has_one :transfer_vendor, through: :transfer_line
  attr_accessor :subcategory_form_id
end

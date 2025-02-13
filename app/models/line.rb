class Line < ApplicationRecord
  belongs_to :trx
  belongs_to :ledger
  delegate :subcategory, to: :ledger
  delegate :category, to: :subcategory
  delegate :vendor, to: :trx
  delegate :account, to: :trx
  delegate :date, to: :trx
  belongs_to :transfer_line, class_name: "Line", optional: true
  # has_one :transferee_line, class_name: "Line", foreign_key: "transfer_line_id"
  # has_one :transfer_vendor, through: :transfer_line
  attr_accessor :subcategory_form_id

  scope :income, -> {
    joins(ledger: { subcategory: :category })
      .merge(Category.income)
  }

  scope :expense, -> {
    joins(ledger: { subcategory: :category })
      .merge(Category.expense)
  }

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "amount", "ledger_id", "transfer_line_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "ledger", "transfer_line", "transfer_vendor", "transferee_line", "trx" ]
  end

  def set_ledger
    ledger = Ledger.find_or_create_by(date: trx.date.end_of_month, subcategory_id: subcategory_form_id)
    self.ledger = ledger
  end
end

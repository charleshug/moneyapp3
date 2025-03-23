class Trx < ApplicationRecord
  require "csv"

  validates :date, presence: true
  validates :lines, presence: { message: "A transaction must have at least one line." }
  belongs_to :account
  belongs_to :vendor
  has_many :lines, dependent: :destroy
  delegate :budget, to: :account
  accepts_nested_attributes_for :lines, allow_destroy: true

  scope :income, -> {
    joins(lines: { ledger: { subcategory: :category } })
    .where(categories: Category.income)
  }
  scope :expense, -> {
    joins(lines: { ledger: { subcategory: :category } })
    .where(categories: Category.expense)
  }

  # Add a scope to filter transfer children
  scope :transfer_children, -> { where(transfer_child: true) }
  scope :not_transfer_children, -> { where(transfer_child: false) }

  scope :within_dates, ->(start_date, end_date) { where(date: start_date..end_date) }

  def self.ransackable_attributes(auth_object = nil)
    # [ "account_id", "amount", "category_id", "subcategory_id", "cleared", "created_at", "date", "id", "id_value", "memo", "transfer_id", "updated_at", "vendor_id" ]
    [ "account_id", "amount", "category_id", "subcategory_id", "cleared", "created_at", "date", "id", "id_value", "memo", "transfer_id", "updated_at", "vendor_id", "lines_ledger_subcategory_category_id", "transfer_child" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # note: these match belongs_to (no plurals)
    #   [ "account", "category", "subcategory", "vendor", "lines" ]
    [ "account", "vendor", "lines", "lines.ledger", "lines.ledger.subcategory", "lines.ledger.subcategory.category" ]
  end

  def set_amount
    # self.amount = lines.sum(:amount) #This will sum the amount values stored in the database
    self.amount = lines.map(&:amount).sum  # This will sum the `amount` values from in-memory objects.
  end

  # Helper method to find the parent transaction
  def parent_transaction
    return nil unless transfer_child?

    # A transfer child has exactly one line with a transfer_line_id
    parent_line = lines.first&.transfer_line
    parent_line&.trx
  end
end

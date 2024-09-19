class Category < ApplicationRecord
  belongs_to :budget
  has_many :subcategories, dependent: :destroy
  # has_many :trxes, through: :subcategories
  has_many :lines, through: :subcategories
  has_many :ledgers, through: :subcategories

  validates :name, presence: true

  scope :income,  -> { where(normal_balance: "INCOME") }
  scope :expense, -> { where(normal_balance: "EXPENSE") }

  DEFAULT_CATEGORY_TYPES = [ "INCOME", "EXPENSE" ]

  DEFAULT_CATEGORIES_BUSINESS = [
    { "Other" => [ "Pre-MoneyApp", "Transfer", "Uncategorized" ] },
    { "Sales Expenses" => [ "Materials", "Sales Allowances" ] },
    { "Operating Expenses" => [ "Payroll", "Rent", "Petty Cash" ] }
  ]

  DEFAULT_CATEGORIES_PERSONAL = [
    { "Other" => [ "Pre-MoneyApp", "Transfer", "Uncategorized" ] },
    { "Everyday" => [ "Groceries", "Restaurants", "Clothing", "Entertainment", "Gas", "Household & Cleaning", "MISC" ] },
    { "Monthly" => [ "Rent", "Phone", "Internet & Utilities", "News Subscriptions", "Car Insurance", "Car Registration", "Retirement" ] },
    { "Irregular" => [ "Investment", "Taxes" ] },
    { "Sinking" => [ "Medical / Dental", "Gifts", "Computer Stuff", "Vacation", "Car Repairs & Maint", "New Phone" ] }
  ]

  def self.ransackable_attributes(auth_object = nil)
    [ "name" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # note: these match belongs_to (no plurals)
    [ "subcategories", "trxes", "name" ]
  end
end

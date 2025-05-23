class Category < ApplicationRecord
  include RailsSortable::Model
  set_sortable :order

  belongs_to :budget
  has_many :subcategories, dependent: :destroy
  # has_many :trxes, through: :subcategories
  has_many :lines, through: :subcategories
  has_many :ledgers, through: :subcategories

  validates :name, presence: true
  validates :order, uniqueness: { scope: :budget_id }

  # Add default ordering with table name and eager load subcategories
  default_scope { order("categories.order") }

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
    { "Everyday" => [ "Groceries", "Restaurants", "Clothing", "Entertainment", "Fuel", "Household & Cleaning", "MISC" ] },
    { "Monthly" => [ "Rent", "Phone", "Internet & Utilities", "News Subscriptions", "Car Insurance", "Car Registration", "Retirement" ] },
    { "Irregular" => [ "Investment", "Taxes" ] },
    { "Sinking" => [ "Medical / Dental", "Gifts", "Computer Stuff", "Vacation", "Car Repairs & Maint", "New Phone" ] }
  ]

  def self.ransackable_attributes(auth_object = nil)
    [ "budget_id", "created_at", "hidden", "id", "name", "normal_balance", "order", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "budget", "subcategories" ]
  end

  # Add a method to initialize order values if needed
  def self.initialize_orders(budget_id)
    where(budget_id: budget_id).order(:created_at).each_with_index do |category, index|
      category.update_column(:order, index + 1) if category.order.nil?
    end
  end
end

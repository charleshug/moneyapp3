class Budget < ApplicationRecord
  attr_accessor :budget_type
  belongs_to :user
  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :subcategories, through: :categories
  has_many :ledgers, through: :subcategories
  has_many :vendors, dependent: :destroy
  has_many :trxes, through: :accounts

  after_create :create_default_vendors
  after_create :create_default_categories

  BUDGET_TYPES = [ "PERSONAL", "BUSINESS" ]

  private

  def create_default_categories
    if budget_type && budget_type == "BUSINESS"
      default_categories = Category::DEFAULT_CATEGORIES_BUSINESS
    else
      default_categories = Category::DEFAULT_CATEGORIES_PERSONAL
    end
    default_categories.each do |category_hash|
      category_hash.each do |category_name, subcategory_names|
        category = self.categories.create(name: category_name)
        subcategory_names.each do |subcategory_name|
          category.subcategories.create(name: subcategory_name)
        end
      end
    end
    category = self.categories.create(name: "Income Parent", normal_balance: "INCOME")
    category.subcategories.create(name: "Income")
  end

  def create_default_vendors
    Vendor::DEFAULT_VENDORS.each do |vendor|
      self.vendors.create(name: vendor)
    end
  end
end

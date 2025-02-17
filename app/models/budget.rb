class Budget < ApplicationRecord
  attr_accessor :budget_type
  belongs_to :user
  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :subcategories, through: :categories
  has_many :ledgers, through: :subcategories
  has_many :vendors, dependent: :destroy
  has_many :trxes, through: :accounts
  has_many :lines, through: :trxes

  after_create :create_default_vendors
  after_create :create_default_categories

  BUDGET_TYPES = [ "PERSONAL", "BUSINESS" ]

  private

  def load_default_categories
    (budget_type == "BUSINESS" ? Category::DEFAULT_CATEGORIES_BUSINESS : Category::DEFAULT_CATEGORIES_PERSONAL)
      .inject({}) { |acc, hash| acc.merge(hash) }
  end

  def create_default_categories
    default_categories = load_default_categories

    # Batch insert categories
    category_data = default_categories.keys.map do |category_name|
      { name: category_name, budget_id: id, created_at: Time.current, updated_at: Time.current }
    end
    inserted_categories = Category.insert_all(category_data, returning: %w[id name])

    # Map inserted categories by name
    category_ids = inserted_categories.index_by { |c| c["name"] }

    # Prepare batch insert for subcategories
    subcategory_data = default_categories.flat_map do |category_name, subcategories|
      subcategories.map do |subcategory_name|
        { name: subcategory_name, category_id: category_ids[category_name]["id"], created_at: Time.current, updated_at: Time.current }
      end
    end
    Subcategory.insert_all(subcategory_data)

    # Insert Income Parent category
    income_category = categories.create(name: "Income Parent", normal_balance: "INCOME")
    income_category.subcategories.create(name: "Income")
  end

  def create_default_vendors
    Vendor::DEFAULT_VENDORS.each do |vendor|
      self.vendors.create(name: vendor)
    end
  end
end

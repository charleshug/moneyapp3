FactoryBot.define do
  factory :subcategory do
    name { "Test Subcategory" }
    association :category
    # sequence(:order) { |n| n }
  end
end

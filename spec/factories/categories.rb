FactoryBot.define do
  factory :category do
    name { "Test Category" }
    association :budget
    # sequence(:order) { |n| n }
  end
end

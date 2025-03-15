FactoryBot.define do
  factory :vendor do
    name { "Test Vendor" }
    association :budget
  end
end

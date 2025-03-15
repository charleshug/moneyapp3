FactoryBot.define do
  factory :account do
    name { "Test Account" }
    association :budget
  end
end

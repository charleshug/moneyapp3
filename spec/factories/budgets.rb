FactoryBot.define do
  factory :budget do
    name { "Test Budget" }
    association :user
  end
end

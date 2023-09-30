FactoryBot.define do
  factory :package do
    sequence(:name) { |n| "Package ##{n}" }
  end
end

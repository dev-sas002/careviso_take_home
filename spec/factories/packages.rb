FactoryBot.define do
  factory :package do
    sequence(:name) { |n| "Package ##{n}" }

    trait :with_products do
       products { [ ] }
    end
  end
end

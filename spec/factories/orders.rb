FactoryBot.define do
  factory :order do
    trait :with_products do
       products { [ ] }
    end
  end
end

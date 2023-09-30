FactoryBot.define do
  factory :order do
    # Order validates presence of products, so the default factory has to
    # build a valid one. Pass `products:` explicitly to control the contents.
    products { [FactoryBot.create(:product)] }
  end
end

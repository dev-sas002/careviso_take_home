require 'rails_helper'

RSpec.describe Product, type: :model do
  describe "associations" do
    it { should have_many(:order_products) }
    it { should have_many(:orders).through(:order_products) }
  end

  describe "validations" do
    subject { create(:product) }
    it { should validate_uniqueness_of(:name) }
  end
end

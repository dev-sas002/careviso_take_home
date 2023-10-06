require "rails_helper"

RSpec.describe Product, type: :model do
  describe "associations" do
    it { should have_many(:order_products).dependent(:destroy) }
    it { should have_many(:orders).through(:order_products) }
    it { should have_many(:package_products).dependent(:destroy) }
    it { should have_many(:packages).through(:package_products) }
  end

  describe "validations" do
    subject { create(:product) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe "#destroy" do
    let!(:product) { create(:product) }

    it "removes the package join records without raising a foreign key error" do
      create(:package, products: [product])
      expect { product.destroy }.to change(PackageProduct, :count).by(-1)
    end

    it "removes the order join records without raising a foreign key error" do
      create(:order, products: [product])
      expect { product.destroy }.to change(OrderProduct, :count).by(-1)
    end
  end
end

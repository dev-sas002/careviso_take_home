require "rails_helper"

RSpec.describe Order, type: :model do
  describe "associations" do
    it { should have_many(:order_products).dependent(:destroy) }
    it { should have_many(:products).through(:order_products) }
  end

  describe "validations" do
    it "is invalid without products" do
      order = Order.new
      expect(order).not_to be_valid
      expect(order.errors[:products]).to include("can't be blank")
    end

    it "is valid with at least one product" do
      expect(Order.new(products: [create(:product)])).to be_valid
    end
  end

  describe "#destroy" do
    let!(:product) { create(:product) }
    let!(:order) { create(:order, products: [product]) }

    it "removes the join records without raising a foreign key error" do
      expect { order.destroy }.to change(OrderProduct, :count).by(-1)
    end

    it "leaves the products in place" do
      order.destroy
      expect(Product.exists?(product.id)).to be true
    end
  end
end

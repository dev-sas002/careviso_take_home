require "rails_helper"

RSpec.describe Package, type: :model do
  describe "associations" do
    it { should have_many(:package_products).dependent(:destroy) }
    it { should have_many(:products).through(:package_products) }
  end

  describe "validations" do
    subject { create(:package) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe "#destroy" do
    let!(:product) { create(:product) }
    let!(:package) { create(:package, products: [product]) }

    it "removes the join records and leaves the products alone" do
      expect { package.destroy }.to change(PackageProduct, :count).by(-1)
      expect(Product.exists?(product.id)).to be true
    end
  end
end

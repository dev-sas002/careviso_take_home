require "rails_helper"

# "Ship each ordered product exactly once" only means something if a product
# cannot be attached to the same order (or package) twice.
RSpec.describe "join models" do
  let(:product) { create(:product) }

  describe OrderProduct do
    let(:order) { create(:order, products: [product]) }

    it { is_expected.to belong_to(:order) }
    it { is_expected.to belong_to(:product) }

    it "rejects a duplicate product on the same order" do
      duplicate = described_class.new(order: order, product: product)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:product_id]).to be_present
    end

    it "allows the same product on a different order" do
      other = create(:order, products: [create(:product)])

      expect(described_class.new(order: other, product: product)).to be_valid
    end

    it "is enforced by the database as well" do
      expect do
        described_class.insert_all!([{ order_id: order.id, product_id: product.id, created_at: Time.current,
                                       updated_at: Time.current }])
      end
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe PackageProduct do
    let(:package) { create(:package, products: [product]) }

    it { is_expected.to belong_to(:package) }
    it { is_expected.to belong_to(:product) }

    it "rejects a duplicate product in the same package" do
      duplicate = described_class.new(package: package, product: product)

      expect(duplicate).not_to be_valid
    end

    it "is enforced by the database as well" do
      expect do
        described_class.insert_all!([{ package_id: package.id, product_id: product.id, created_at: Time.current,
                                       updated_at: Time.current }])
      end
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end

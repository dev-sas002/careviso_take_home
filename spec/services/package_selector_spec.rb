require 'rails_helper'

RSpec.describe PackageSelector do
  let(:product_a) { create(:product, name: "ProductA") }
  let(:product_b) { create(:product, name: "ProductB") }
  let(:product_c) { create(:product, name: "ProductC") }

  let(:order) { create(:order, :with_products, products: [product_a, product_b, product_c]).products.map(&:name) }

  let(:packages) {
    [
      create(:package, :with_products, products: [product_a, product_b]),
      create(:package, :with_products, products: [product_c])
    ].map { |package| { package.name => package.products.pluck(:name) } }
  }

  describe '.fulfill_order?' do
    context 'when all order products are included in the combined packages' do
      it 'returns true' do
        result = described_class.fulfill_order?(order, packages.flat_map(&:values).flatten)
        expect(result).to be true
      end
    end

    context 'when not all order products are in the combined packages' do
      it 'returns false' do
        result = described_class.fulfill_order?(order, ["ProductA"])
        expect(result).to be false
      end
    end
  end

  describe '.find_optimal_combination' do
    context 'when an optimal combination is found' do
      it 'returns the optimal package names' do
        result = described_class.find_optimal_combination(order, packages)
        expected_names = packages.map { |package| package.keys.first }
        expect(result).to match_array(expected_names)
      end
    end

    context 'when no optimal combination is found' do
      it 'returns nil' do
        result = described_class.find_optimal_combination(order, [])
        expect(result).to be_nil
      end
    end
  end

  describe '.extra_products?' do
    context 'when there are extra products in the combination' do
      it 'returns true' do
        result = described_class.extra_products?(order, %w[ProductA ProductB ProductC ProductD])
        expect(result).to be true
      end
    end

    context 'when there are no extra products in the combination' do
      it 'returns false' do
        result = described_class.extra_products?(order, order)
        expect(result).to be false
      end
    end
  end

  describe '.select_optimal_packages' do
    context 'when an optimal package combination exists' do
      it 'returns the optimal package names' do
        result = described_class.select_optimal_packages(order, packages)
        expected_names = packages.map { |package| package.keys.first }
        expect(result).to match_array(expected_names)
      end
    end

    context 'when no optimal package combination exists' do
      it 'returns nil' do
        result = described_class.select_optimal_packages(order, [])
        expect(result).to be_nil
      end
    end
  end
end

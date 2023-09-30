require "rails_helper"

# PackageSelector is a pure function over plain Ruby data:
#   order    -> Array of product names
#   packages -> Array of { package_name => [product names] }
# so these examples use literal data rather than database records. The
# database-backed path is covered by spec/services/package_selection/shipment_for_order_spec.rb.
RSpec.describe PackageSelector do
  let(:order) { %w[ProductA ProductB ProductC] }

  let(:packages) do
    [
      { "Package1" => %w[ProductA ProductB] },
      { "Package2" => %w[ProductC] }
    ]
  end

  describe ".select_optimal_packages" do
    it "returns the smallest set of packages that ships the order exactly" do
      expect(described_class.select_optimal_packages(order, packages))
        .to match_array(%w[Package1 Package2])
    end

    it "prefers a single package over a multi-package combination" do
      candidates = packages + [{ "Package3" => order }]

      expect(described_class.select_optimal_packages(order, candidates)).to eq(%w[Package3])
    end

    it "returns nil rather than shipping surplus products" do
      candidates = [{ "Big" => order + %w[ProductD] }]

      expect(described_class.select_optimal_packages(order, candidates)).to be_nil
    end

    it "returns nil when a product in the order is in no package" do
      expect(described_class.select_optimal_packages(order + %w[ProductZ], packages)).to be_nil
    end

    context "when the order or the catalogue is empty" do
      it "returns nil for a nil order" do
        expect(described_class.select_optimal_packages(nil, packages)).to be_nil
      end

      it "returns nil for an empty order" do
        expect(described_class.select_optimal_packages([], packages)).to be_nil
      end

      it "returns nil for a nil catalogue" do
        expect(described_class.select_optimal_packages(order, nil)).to be_nil
      end

      it "returns nil for an empty catalogue" do
        expect(described_class.select_optimal_packages(order, [])).to be_nil
      end
    end

    context "with an explicit strategy" do
      it "uses the named strategy" do
        expect(PackageSelection::Strategies::BruteForce).to receive(:call).and_call_original

        described_class.select_optimal_packages(order, packages, strategy: :brute_force)
      end

      it "raises for a strategy nobody registered" do
        expect { described_class.select_optimal_packages(order, packages, strategy: :magic) }
          .to raise_error(PackageSelection::UnknownStrategyError)
      end
    end
  end
end

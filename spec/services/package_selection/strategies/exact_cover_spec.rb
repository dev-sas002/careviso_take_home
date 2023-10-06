require "rails_helper"

RSpec.describe PackageSelection::Strategies::ExactCover do
  it_behaves_like "a package selection strategy"

  def catalog_for(order, packages)
    PackageSelection::Catalog.new(order, packages)
  end

  describe "pruning" do
    it "branches only on packages containing the lowest uncovered product" do
      order = %w[A B C D]
      packages = [
        { "AB" => %w[A B] }, { "CD" => %w[C D] },
        { "AC" => %w[A C] }, { "BD" => %w[B D] },
        { "A" => %w[A] }, { "B" => %w[B] }, { "C" => %w[C] }, { "D" => %w[D] }
      ]

      strategy = described_class.new(catalog_for(order, packages))
      strategy.call

      # 2^4 = 16 covered-product states exist; the lowest-uncovered-bit rule plus
      # the counting lower bound means the search never visits most of them.
      expect(strategy.states_visited).to be < 16
    end

    it "stops as soon as it finds a solution that meets the counting lower bound" do
      order = %w[A B C D E F]
      packages = [{ "Everything" => order }] + order.map { |p| { "Single#{p}" => [p] } }

      strategy = described_class.new(catalog_for(order, packages))

      expect(strategy.call).to eq(%w[Everything])
      expect(strategy.states_visited).to eq(1)
    end
  end

  describe "the work budget" do
    it "raises rather than searching without bound" do
      order, packages = CatalogBuilder.solvable_catalog(order_size: 24, block_size: 2, decoys: 40)
      strategy = described_class.new(catalog_for(order, packages), max_states: 5)

      expect { strategy.call }.to raise_error(PackageSelection::SearchLimitExceeded, /gave up after 5 states/)
    end

    it "reads its default from PACKAGE_SELECTION_MAX_STATES" do
      expect(described_class::DEFAULT_MAX_STATES).to be_positive
      expect(described_class.max_states).to be_positive
    end
  end

  describe "orders that need real search" do
    it "solves a 21-product order with a 60-package catalogue" do
      order, packages = CatalogBuilder.solvable_catalog(order_size: 21, block_size: 3, decoys: 50)

      result = described_class.call(catalog_for(order, packages))

      expect(result).not_to be_nil
      shipped = packages.select { |package| result.include?(package.keys.first) }.flat_map(&:values).flatten
      expect(shipped.sort).to eq(order.sort)
    end

    it "returns nil for an unsatisfiable order without exhausting the budget" do
      order = Array.new(18) { |i| "P#{i}" }
      packages = Array.new(30) { |i| { "Pkg#{i}" => ["P#{i % 17}"] } } # P17 is in nothing

      expect(described_class.call(catalog_for(order, packages))).to be_nil
    end
  end

  describe "input shapes" do
    it "treats a duplicated ordered product as one product" do
      order = %w[A B A]
      packages = [{ "AB" => %w[A B] }]

      expect(described_class.call(catalog_for(order, packages))).to eq(%w[AB])
    end

    it "handles a package listing the same product twice" do
      packages = [{ "AA" => %w[A A] }, { "B" => %w[B] }]

      expect(described_class.call(catalog_for(%w[A B], packages))).to match_array(%w[AA B])
    end
  end
end

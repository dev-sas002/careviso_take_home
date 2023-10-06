require "rails_helper"

RSpec.describe PackageSelection::Catalog do
  subject(:catalog) { described_class.new(order, packages) }

  let(:order) { %w[A B C] }
  let(:packages) { [{ "AB" => %w[A B] }, { "C" => %w[C] }] }

  describe "normalisation" do
    it "maps each ordered product to a bit and each package to a mask" do
      expect(catalog.products).to eq(%w[A B C])
      expect(catalog.full_mask).to eq(0b111)
      expect(catalog.candidates.map(&:name)).to contain_exactly("AB", "C")
      expect(catalog.candidates.map(&:mask).reduce(:|)).to eq(0b111)
    end

    it "collapses a product the order lists twice" do
      expect(described_class.new(%w[A A B], packages).products).to eq(%w[A B])
    end

    it "accepts a single hash of many packages as well as an array of hashes" do
      from_hash = described_class.new(order, { "AB" => %w[A B], "C" => %w[C] })

      expect(from_hash.candidates.map(&:name)).to eq(catalog.candidates.map(&:name))
    end
  end

  describe "filtering" do
    it "drops packages holding a product the order did not ask for" do
      catalog = described_class.new(order, packages + [{ "Surplus" => %w[A D] }])

      expect(catalog.candidates.map(&:name)).not_to include("Surplus")
    end

    it "drops empty packages" do
      catalog = described_class.new(order, packages + [{ "Empty" => [] }])

      expect(catalog.candidates.map(&:name)).not_to include("Empty")
    end

    it "keeps only one of two packages with identical contents" do
      catalog = described_class.new(order, [{ "First" => %w[A B] }, { "Second" => %w[A B] }])

      expect(catalog.candidates.map(&:name)).to eq(%w[First])
    end

    it "orders candidates largest first so the search meets good answers early" do
      catalog = described_class.new(order, [{ "C" => %w[C] }, { "AB" => %w[A B] }])

      expect(catalog.candidates.map(&:name)).to eq(%w[AB C])
    end
  end

  describe "#coverable?" do
    it "is false when the surviving packages cannot touch every ordered product" do
      expect(described_class.new(order, [{ "AB" => %w[A B] }])).not_to be_coverable
    end

    it "is true when they can, even if no exact combination exists" do
      catalog = described_class.new(order, [{ "AB" => %w[A B] }, { "BC" => %w[B C] }])

      expect(catalog).to be_coverable
    end
  end

  describe "#empty?" do
    it "is true without an order" do
      expect(described_class.new([], packages)).to be_empty
      expect(described_class.new(nil, packages)).to be_empty
    end

    it "is true when no package survives filtering" do
      expect(described_class.new(order, nil)).to be_empty
      expect(described_class.new(order, [{ "Surplus" => %w[Z] }])).to be_empty
    end
  end

  describe "#product_names" do
    it "reads a mask back as product names" do
      expect(catalog.product_names(0b101)).to eq(%w[A C])
    end
  end

  describe "#candidates_by_bit" do
    it "indexes candidates by the products they contain" do
      by_bit = catalog.candidates_by_bit

      expect(by_bit[0b001].map(&:name)).to eq(%w[AB])
      expect(by_bit[0b100].map(&:name)).to eq(%w[C])
    end
  end
end

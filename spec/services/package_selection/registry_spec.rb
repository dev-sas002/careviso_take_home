require "rails_helper"

RSpec.describe PackageSelection::Registry do
  after { described_class.reset! }

  it "ships both built-in strategies" do
    expect(described_class.names).to include(:exact_cover, :brute_force)
    expect(described_class.fetch(:exact_cover)).to eq(PackageSelection::Strategies::ExactCover)
    expect(described_class.fetch(:brute_force)).to eq(PackageSelection::Strategies::BruteForce)
  end

  it "defaults to the exact cover solver" do
    described_class.reset!

    expect(described_class.default).to eq(:exact_cover)
    expect(described_class.fetch(nil)).to eq(PackageSelection::Strategies::ExactCover)
  end

  it "accepts a new strategy without any change to existing code" do
    first_only = Class.new(PackageSelection::Strategies::Base) do
      def call
        catalog.candidates.first(1).map(&:name)
      end
    end
    stub_const("FirstOnlyStrategy", first_only)

    described_class.register(:first_only, FirstOnlyStrategy)

    expect(described_class).to be_registered(:first_only)
    expect(PackageSelector.select_optimal_packages(%w[A B], [{ "AB" => %w[A B] }], strategy: :first_only))
      .to eq(%w[AB])
  end

  it "raises a helpful error for an unknown strategy" do
    expect { described_class.fetch(:does_not_exist) }
      .to raise_error(PackageSelection::UnknownStrategyError, /unknown package selection strategy :does_not_exist/)
  end

  it "can have its default swapped at runtime" do
    described_class.default = :brute_force

    expect(described_class.fetch(nil)).to eq(PackageSelection::Strategies::BruteForce)
  end
end

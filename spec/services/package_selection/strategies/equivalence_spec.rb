require "rails_helper"

# The fast algorithm is only worth having if it is also right. These examples
# put ExactCover and the obvious exhaustive search side by side on hundreds of
# randomised catalogues and assert that they agree — not necessarily on *which*
# minimal shipment, since several can tie, but always on whether one exists and
# on how many packages it takes.
RSpec.describe "package selection strategies agree" do
  def shipment(strategy, order, packages)
    strategy.call(PackageSelection::Catalog.new(order, packages))
  end

  def assert_exact!(order, packages, result)
    return if result.nil?

    shipped = packages.select { |package| result.include?(package.keys.first) }
                      .flat_map(&:values).flatten
    expect(shipped.sort).to eq(order.uniq.sort), "shipment #{result.inspect} was not exact"
  end

  # Small enough that the exhaustive search is affordable, varied enough that
  # most catalogues have no answer at all — which is the case most likely to be
  # got wrong.
  it "agrees on 400 randomised catalogues" do
    random = Random.new(20_260_923)
    disagreements = []

    400.times do |i|
      order, packages = CatalogBuilder.random_catalog(
        order_size: random.rand(1..7),
        package_count: random.rand(1..9),
        noise: random.rand(0..3),
        random: random
      )

      fast = shipment(PackageSelection::Strategies::ExactCover, order, packages)
      slow = shipment(PackageSelection::Strategies::BruteForce, order, packages)

      assert_exact!(order, packages, fast)
      disagreements << [i, order, packages, fast, slow] if fast&.size != slow&.size
    end

    expect(disagreements).to be_empty, -> { "first disagreement: #{disagreements.first.inspect}" }
  end

  it "agrees on catalogues built to be solvable" do
    10.times do |i|
      order, packages = CatalogBuilder.solvable_catalog(
        order_size: 9, block_size: 3, decoys: 6, random: Random.new(i)
      )

      fast = shipment(PackageSelection::Strategies::ExactCover, order, packages)
      slow = shipment(PackageSelection::Strategies::BruteForce, order, packages)

      expect(fast).not_to be_nil
      expect(fast.size).to eq(slow.size)
      assert_exact!(order, packages, fast)
    end
  end
end

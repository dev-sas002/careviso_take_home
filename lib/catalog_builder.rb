# Builds randomised-but-reproducible catalogues.
#
# Used by the property specs ("does the fast algorithm agree with the obvious
# one?", asked a few hundred times) and by `rake package_selection:benchmark`.
# Lives in lib/ rather than spec/ so the benchmark can load it outside the test
# environment.
module CatalogBuilder
  module_function

  # A catalogue with no guarantees: most of these orders cannot be shipped
  # exactly at all, which is the case most likely to be got wrong.
  #
  # @param order_size [Integer] distinct products on the order
  # @param package_count [Integer] packages in the catalogue
  # @param noise [Integer] products that exist but were not ordered
  # @return [Array(Array<String>, Array<Hash>)] the order and the catalogue
  def random_catalog(order_size:, package_count:, noise: 0, random: Random.new(1234))
    order = Array.new(order_size) { |i| "P#{i}" }
    universe = order + Array.new(noise) { |i| "X#{i}" }

    packages = Array.new(package_count) do |i|
      size = random.rand(1..[universe.size, 4].min)
      { "Pkg#{i}" => universe.sample(size, random: random).uniq }
    end

    [order, packages]
  end

  # A catalogue guaranteed to contain at least one exact answer: the order is cut
  # into consecutive blocks, then buried in decoys. Half the decoys hold a
  # product nobody ordered, so they model the packages a real catalogue would be
  # full of — and which never reach the solver.
  def solvable_catalog(order_size:, block_size: 3, decoys: 10, noise_fraction: 0.5, random: Random.new(4321))
    order = Array.new(order_size) { |i| "P#{i}" }

    packages = order.each_slice(block_size).with_index.map { |block, i| { "Block#{i}" => block } }

    decoys.times do |i|
      contents = order.sample(random.rand(1..3), random: random).uniq
      contents << "X#{i}" if random.rand < noise_fraction
      packages << { "Decoy#{i}" => contents }
    end

    [order, packages.shuffle(random: random)]
  end

  # The adversarial case: every package holds exactly two products, so an exact
  # shipment is a perfect matching on the ordered products. With an odd number of
  # products there is none, and the search has to prove it — no early exit, no
  # useful lower bound. This is what the work budget exists for.
  def all_pairs_catalog(order_size:)
    order = Array.new(order_size) { |i| "P#{i}" }
    packages = order.combination(2).map { |pair| { "Pair#{pair.join("-")}" => pair } }

    [order, packages]
  end
end

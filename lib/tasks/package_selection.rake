# Numbers, not adjectives.
#
#   bundle exec rake package_selection:benchmark
#
# Times the exact-cover solver against the exhaustive search it replaced, on
# synthetic catalogues that grow along the two axes that matter: how many
# products are on the order, and how many packages are in the catalogue.
require "benchmark"

BENCHMARK_CASES = [
  { order_size: 3,  package_count: 6,    label: "the brief's example" },
  { order_size: 8,  package_count: 40,   label: "a small warehouse" },
  { order_size: 12, package_count: 200,  label: "a real catalogue" },
  { order_size: 16, package_count: 1_000, label: "a big catalogue" },
  { order_size: 20, package_count: 5_000, label: "a very big catalogue" },
  { order_size: 24, package_count: 20_000, label: "a silly catalogue" }
].freeze

BRUTE_FORCE_CEILING = 20 # surviving candidates; above this 2^P stops finishing

namespace :package_selection do
  desc "Benchmark the package selection strategies across catalogue sizes"
  task benchmark: :environment do
    require Rails.root.join("lib/catalog_builder").to_s

    puts format("%-22s %7s %9s %10s %10s %12s %12s",
                "case", "order", "packages", "kept", "packages", "exact cover", "brute force")
    puts "-" * 90

    BENCHMARK_CASES.each do |scenario|
      order, packages = CatalogBuilder.solvable_catalog(
        order_size: scenario[:order_size],
        block_size: 4,
        decoys: scenario[:package_count],
        random: Random.new(17)
      )

      catalog = PackageSelection::Catalog.new(order, packages)
      solver = PackageSelection::Strategies::ExactCover.new(catalog)

      fast_result = nil
      fast = Benchmark.realtime { fast_result = solver.call }

      slow = if catalog.size <= BRUTE_FORCE_CEILING
               Benchmark.realtime { PackageSelection::Strategies::BruteForce.call(catalog) }
             end

      puts format("%-22s %7d %9d %10d %10s %12s %12s",
                  scenario[:label],
                  order.size,
                  packages.size,
                  catalog.size,
                  fast_result&.size || "none",
                  format("%.1f ms", fast * 1000),
                  slow ? format("%.1f ms", slow * 1000) : "n/a")
    end

    puts
    puts "kept      = packages that survive filtering (a superset of the answer)"
    puts "brute force is only run when 2^kept is finishable; n/a means it is not"
  end

  desc "Show how the exact-cover search scales with the size of the order"
  task states: :environment do
    require Rails.root.join("lib/catalog_builder").to_s

    puts format("%7s %9s %10s %14s %12s", "order", "packages", "kept", "states visited", "time")
    puts "-" * 58

    (4..28).step(4) do |order_size|
      order, packages = CatalogBuilder.solvable_catalog(
        order_size: order_size, block_size: 4, decoys: 500, random: Random.new(17)
      )
      catalog = PackageSelection::Catalog.new(order, packages)
      solver = PackageSelection::Strategies::ExactCover.new(catalog)

      elapsed = Benchmark.realtime { solver.call }

      puts format("%7d %9d %10d %14d %12s",
                  order_size, packages.size, catalog.size, solver.states_visited,
                  format("%.1f ms", elapsed * 1000))
    end
  end

  desc "Show how the exact-cover search behaves on adversarial orders"
  task hard: :environment do
    require Rails.root.join("lib/catalog_builder").to_s

    puts "Every package holds exactly two products, so an exact shipment is a perfect"
    puts "matching. With an odd number of products there is none and the search has to"
    puts "prove it: no early exit, no useful lower bound. This is the worst case."
    puts
    puts format("%7s %9s %15s %12s", "order", "packages", "states visited", "time")
    puts "-" * 47

    (7..21).step(2) do |order_size|
      order, packages = CatalogBuilder.all_pairs_catalog(order_size: order_size)
      catalog = PackageSelection::Catalog.new(order, packages)
      solver = PackageSelection::Strategies::ExactCover.new(catalog, max_states: 5_000_000)

      elapsed = Benchmark.realtime { solver.call }

      puts format("%7d %9d %15d %12s",
                  order_size, packages.size, solver.states_visited, format("%.1f ms", elapsed * 1000))
    end
  end
end

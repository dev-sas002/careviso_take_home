# Facade for the packaging problem: given the products on an order and the
# catalogue of packages, return the names of the smallest set of packages whose
# combined contents are *exactly* that order — every ordered product shipped
# once, nothing surplus — or nil when no such set exists.
#
#   PackageSelector.select_optimal_packages(
#     %w[P1 P2 P3],
#     [{ "Package6" => %w[P1 P2] }, { "Package3" => %w[P3] }]
#   )
#   # => ["Package6", "Package3"]
#
# It speaks plain Ruby, not ActiveRecord: the same call works against a database,
# a fixture or a randomised catalogue in a spec. `PackageSelection::ShipmentForOrder`
# is the adapter that feeds it rows from the database.
#
# The work happens in PackageSelection::Strategies; see ExactCover for the
# algorithm and PackageSelection::Registry for how to add another one.
class PackageSelector
  # @param order [Array<String>] product names on the order
  # @param available_packages [Array<Hash>, Hash] `[{ name => [products] }, ...]`
  # @param strategy [Symbol, nil] a name registered with PackageSelection::Registry
  # @return [Array<String>, nil] package names, or nil if the order cannot be shipped exactly
  def self.select_optimal_packages(order, available_packages, strategy: nil)
    catalog = PackageSelection::Catalog.new(order, available_packages)
    return nil if catalog.empty?

    PackageSelection::Registry.fetch(strategy).call(catalog)
  end
end

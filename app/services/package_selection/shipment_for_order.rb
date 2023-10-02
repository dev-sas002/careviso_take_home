require "digest"

module PackageSelection
  # The seam between ActiveRecord and the pure selection code: it turns an Order
  # and the packages table into plain arrays, calls PackageSelector, and caches
  # the answer. Controllers call this; nothing else in the app touches
  # PackageSelector directly.
  #
  # Two things here are load-bearing for performance:
  #
  # * The catalogue is fetched in **one** query, and the "a package containing an
  #   unordered product can never be part of an exact shipment" rule is pushed
  #   into SQL. A warehouse with 50,000 packages still only ships a handful of
  #   rows to Ruby for a three-product order.
  # * The result is cached under a digest of the exact inputs (ordered products +
  #   the surviving catalogue), so re-opening an order does not re-run an NP-hard
  #   search, and any edit to either side produces a different key rather than a
  #   stale answer. Two different orders for the same products share one entry.
  class ShipmentForOrder
    CACHE_NAMESPACE = "package_selection/v1".freeze
    CACHE_TTL = 1.hour

    attr_reader :order, :strategy

    def self.call(order, strategy: nil)
      new(order, strategy: strategy).call
    end

    def initialize(order, strategy: nil)
      @order = order
      @strategy = strategy || Registry.default
    end

    # @return [Array<String>, nil] package names, or nil when the order cannot be
    #   shipped exactly (or has nothing to ship)
    # @raise [PackageSelection::SearchLimitExceeded]
    def call
      return nil if ordered_product_names.empty?

      cached = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { Array(select_packages) }
      cached.presence
    end

    private

    def select_packages
      PackageSelector.select_optimal_packages(ordered_product_names, available_packages, strategy: strategy)
    end

    def ordered_product_names
      @ordered_product_names ||= order.products.pluck(:name).uniq
    end

    def ordered_product_ids
      @ordered_product_ids ||= order.products.pluck(:id).uniq
    end

    # One query, already filtered down to packages that could actually appear in
    # an exact shipment.
    def available_packages
      @available_packages ||= begin
        rows = Package.where.not(id: packages_holding_unordered_products)
                      .joins(:products)
                      .where(products: { id: ordered_product_ids })
                      .pluck("packages.name", "products.name")

        rows.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
      end
    end

    def packages_holding_unordered_products
      PackageProduct.where.not(product_id: ordered_product_ids).select(:package_id)
    end

    def cache_key
      [CACHE_NAMESPACE, strategy, inputs_digest].join("/")
    end

    # The cache is keyed on what the answer actually depends on, not on
    # timestamps: the ordered products and the surviving catalogue.
    def inputs_digest
      payload = [
        ordered_product_names.sort,
        available_packages.map { |name, products| [name, products.sort] }.sort
      ]

      Digest::SHA256.hexdigest(payload.to_s)
    end
  end
end

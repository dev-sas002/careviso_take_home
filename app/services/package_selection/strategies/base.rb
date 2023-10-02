module PackageSelection
  module Strategies
    # The strategy contract: given a Catalog, return the names of the smallest
    # set of packages whose contents are exactly the order, or nil when no such
    # set exists.
    #
    # Strategies must be pure — no database, no clock, no global state — so they
    # can be property-tested against each other.
    class Base
      attr_reader :catalog

      def self.call(catalog)
        new(catalog).call
      end

      def initialize(catalog)
        @catalog = catalog
      end

      def call
        raise NotImplementedError, "#{self.class} must implement #call"
      end
    end
  end
end

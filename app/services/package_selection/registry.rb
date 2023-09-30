module PackageSelection
  # The extension seam.
  #
  # "Smallest set of packages" is one reading of a shipping problem; a warehouse
  # would soon want "cheapest", "fewest touches", "prefer stock in this
  # warehouse", or a heuristic that trades optimality for a bounded runtime.
  # Each of those is the same input and the same output with different logic in
  # the middle, so the seam is a strategy registry rather than a pile of flags.
  #
  # Adding one is three lines and no edits to existing code:
  #
  #   class CheapestShipment < PackageSelection::Strategies::Base
  #     def call = ...
  #   end
  #   PackageSelection::Registry.register(:cheapest, CheapestShipment)
  #
  # Classes are registered by name and resolved lazily so that registering does
  # not fight Rails' autoloader in development.
  module Registry
    BUILT_IN = {
      exact_cover: "PackageSelection::Strategies::ExactCover",
      brute_force: "PackageSelection::Strategies::BruteForce"
    }.freeze

    class << self
      def register(name, strategy)
        registry[name.to_sym] = strategy.is_a?(String) ? strategy : strategy.name
        name.to_sym
      end

      def fetch(name)
        key = (name || default).to_sym
        constant = registry[key] or
          raise UnknownStrategyError, "unknown package selection strategy #{key.inspect} (known: #{names.join(", ")})"

        constant.is_a?(String) ? constant.constantize : constant
      end

      def names
        registry.keys
      end

      def registered?(name)
        registry.key?(name.to_sym)
      end

      # Which strategy PackageSelector uses when the caller does not say.
      def default
        @default ||= ENV.fetch("PACKAGE_SELECTION_STRATEGY", "exact_cover").to_sym
      end

      attr_writer :default

      def reset!
        @registry = BUILT_IN.dup
        @default = nil
      end

      private

      def registry
        @registry ||= BUILT_IN.dup
      end
    end
  end
end

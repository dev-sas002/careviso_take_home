module PackageSelection
  module Strategies
    # Minimum-cardinality exact cover, solved as a memoised search over the set
    # of *already covered products* rather than over the set of packages.
    #
    # Why that flip matters
    # --------------------
    # The obvious implementation enumerates subsets of the catalogue: 2^P states
    # for P packages, and a 40-package catalogue is already out of reach. But two
    # different package subsets that cover the same products leave behind exactly
    # the same remaining problem, so the state that actually matters is the
    # covered-products bitmask — at most 2^n states for an n-product order, and
    # orders are far smaller than catalogues.
    #
    # Three things keep the constant factor down:
    #
    # 1. Candidates are pre-filtered (Catalog drops any package holding a product
    #    the order did not ask for) and reduced to integers, so "does this package
    #    fit alongside what I have already picked?" is one AND.
    # 2. At every step the search picks the *lowest uncovered product* and only
    #    tries packages that contain it. Every exact cover must cover that product
    #    somehow, so this loses no solutions while collapsing the branching factor
    #    from "every package" to "packages holding this one product".
    # 3. A counting lower bound — you cannot cover k products with fewer than
    #    k / (largest package) packages — lets a branch stop as soon as the best
    #    solution found so far is provably optimal.
    #
    # Complexity: O(2^n * P) time and O(2^n) memo entries worst case, where n is
    # the number of distinct products *in the order* and P the number of packages
    # that survive filtering. In practice only unions of disjoint packages are
    # reachable, which is a tiny fraction of 2^n. See `rake package_selection:benchmark`.
    #
    # The problem is NP-hard, so the worst case is unavoidable; `max_states`
    # bounds the damage a pathological order can do inside a web request.
    class ExactCover < Base
      DEFAULT_MAX_STATES = 200_000

      def self.max_states
        @max_states ||= Integer(ENV.fetch("PACKAGE_SELECTION_MAX_STATES", DEFAULT_MAX_STATES))
      end

      class << self
        attr_writer :max_states
      end

      def initialize(catalog, max_states: self.class.max_states)
        super(catalog)
        @max_states = max_states
        @memo = {}
        @states_visited = 0
      end

      # @return [Array<String>, nil] package names, fewest first-fit, or nil
      # @raise [SearchLimitExceeded] if the search outgrows its budget
      def call
        return nil unless catalog.coverable?

        best = search(0)
        best&.map(&:name)
      end

      # Number of distinct sub-problems the search actually looked at. Exposed
      # for the benchmark task and for the specs that pin the pruning down.
      attr_reader :states_visited

      private

      # Best (fewest-package) exact cover of everything *not* in `covered`,
      # as an array of Candidates, or nil when the remainder cannot be covered.
      def search(covered)
        return [] if covered == catalog.full_mask
        return @memo[covered] if @memo.key?(covered)

        track_state!
        @memo[covered] = best_cover(covered)
      end

      def best_cover(covered)
        floor = lower_bound(covered)
        best = nil

        candidates_for_lowest_uncovered(covered).each do |candidate|
          solution = cover_with(covered, candidate)
          next if solution.nil?

          best = solution if best.nil? || solution.size < best.size
          break if best.size <= floor # provably optimal, stop looking
        end

        best
      end

      # Take `candidate`, then solve what is left. nil if it does not fit or the
      # remainder cannot be covered exactly.
      def cover_with(covered, candidate)
        return nil unless candidate.disjoint_from?(covered)

        remainder = search(covered | candidate.mask)
        remainder && [candidate, *remainder]
      end

      def candidates_for_lowest_uncovered(covered)
        catalog.candidates_by_bit.fetch(lowest_uncovered_bit(covered))
      end

      # The lowest-numbered product the order still needs. Every exact cover has
      # to include a package containing it, which is what makes branching on it
      # both complete and cheap.
      def lowest_uncovered_bit(covered)
        uncovered = catalog.full_mask & ~covered
        uncovered & -uncovered
      end

      def lower_bound(covered)
        remaining = (catalog.full_mask & ~covered).to_s(2).count("1")
        (remaining.to_f / catalog.largest_candidate_size).ceil
      end

      def track_state!
        @states_visited += 1
        return if @states_visited <= @max_states

        raise SearchLimitExceeded,
              "package selection gave up after #{@max_states} states " \
              "(#{catalog.products.size} products, #{catalog.size} candidate packages)"
      end
    end
  end
end

module PackageSelection
  module Strategies
    # The naive reading of the brief: try every subset of the catalogue, smallest
    # subsets first, and return the first one whose contents are exactly the
    # order. Correct by construction and easy to believe, which is precisely what
    # makes it useful — the spec suite runs it against ExactCover on thousands of
    # randomised catalogues and asserts the two always agree on the *size* of the
    # answer.
    #
    # Complexity: O(2^P) subsets for P surviving packages. Keep it away from
    # anything that is not a test or a benchmark; it is registered as
    # `:brute_force` so the seam has a second, honest implementation rather than
    # a hypothetical one.
    class BruteForce < Base
      def call
        return nil unless catalog.coverable?

        candidates = catalog.candidates
        (1..candidates.size).each do |size|
          candidates.combination(size) do |combination|
            return combination.map(&:name) if exact?(combination)
          end
        end

        nil
      end

      private

      # Exact means two things at once: every ordered product present, and
      # nothing shipped twice or over. Both fall out of one comparison once the
      # packages are bitmasks — overlapping packages sum to fewer bits than their
      # sizes add up to.
      def exact?(combination)
        union = combination.reduce(0) { |acc, candidate| acc | candidate.mask }
        return false unless union == catalog.full_mask

        combination.sum(&:product_count) == catalog.products.size
      end
    end
  end
end

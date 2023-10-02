module PackageSelection
  # Normalises "an order and a list of packages" into the bitmask form every
  # strategy works on.
  #
  # Two products, two representations:
  #
  #   order    ["P1", "P2", "P3"]        -> bit 0, bit 1, bit 2
  #   packages [{ "Box" => %w[P1 P3] }]  -> Candidate(name: "Box", mask: 0b101)
  #
  # Building the catalogue is also where the cheap wins live. A package that
  # contains any product the order did not ask for can never appear in an exact
  # shipment, so it is dropped here and the search never sees it. In a real
  # catalogue that removes the overwhelming majority of rows.
  class Catalog
    attr_reader :products, :candidates, :full_mask

    # @param order [Array<String>] product names the customer ordered
    # @param packages [Array<Hash>, Hash] either `[{ name => [products] }, ...]`
    #   or a single `{ name => [products] }` hash
    def initialize(order, packages)
      @products = normalise_order(order)
      @bit_for = @products.each_with_index.to_h { |name, index| [name, 1 << index] }
      @full_mask = (1 << @products.size) - 1
      @candidates = build_candidates(packages)
    end

    # No order, or no package that is even a subset of the order.
    def empty?
      @products.empty? || @candidates.empty?
    end

    # True when the candidates *between them* touch every ordered product. If
    # they do not, no exact shipment exists and the search can be skipped.
    def coverable?
      return false if empty?

      @candidates.reduce(0) { |acc, candidate| acc | candidate.mask } == full_mask
    end

    # The largest package on offer, used as the denominator of the search's
    # lower bound (you can never cover k products with fewer than k / largest
    # packages).
    def largest_candidate_size
      @largest_candidate_size ||= @candidates.map(&:product_count).max || 0
    end

    # Candidates grouped by the individual product bits they cover, so the
    # search can ask "which packages could supply *this* product?" in O(1).
    def candidates_by_bit
      @candidates_by_bit ||= @products.each_with_index.to_h do |_name, index|
        bit = 1 << index
        [bit, @candidates.select { |candidate| candidate.covers?(bit) }]
      end
    end

    def product_names(mask)
      @products.each_with_index.filter_map { |name, index| name if mask[index] == 1 }
    end

    def size
      @candidates.size
    end

    private

    def normalise_order(order)
      Array(order).flatten.compact.map(&:to_s).uniq
    end

    # Rejects packages that are empty, that contain an unordered product, or
    # that duplicate a package already accepted. Sorted largest-first (ties
    # broken by name) so that the search meets good solutions early — which is
    # what makes its lower-bound pruning bite — and so that its answer is
    # deterministic for a given input.
    def build_candidates(packages)
      each_package(packages)
        .filter_map { |name, product_names| candidate_for(name, product_names) }
        .sort_by { |candidate| [-candidate.product_count, candidate.name] }
        .uniq(&:mask) # two packages with identical contents are interchangeable
    end

    def candidate_for(name, product_names)
      mask = 0
      Array(product_names).flatten.compact.each do |product|
        bit = @bit_for[product.to_s]
        return nil if bit.nil? # surplus product: this package can never be exact

        mask |= bit
      end
      return nil if mask.zero?

      Candidate.new(name: name.to_s, mask: mask, product_count: mask.to_s(2).count("1"))
    end

    # Accepts the shapes callers actually have: one hash of many packages, an
    # array of single-pair hashes, or an array of [name, products] pairs.
    def each_package(packages, &block)
      return enum_for(:each_package, packages) unless block_given?

      entries = packages.is_a?(Hash) ? [packages] : Array(packages)
      entries.each { |entry| each_pair(entry, &block) }
    end

    def each_pair(entry, &block)
      case entry
      when Hash then entry.each(&block)
      when Array then yield(entry.first, entry.last)
      end
    end
  end
end

module PackageSelection
  # A single package, reduced to the only three things the search cares about:
  # its name, the bitmask of ordered products it covers, and how many products
  # that mask represents.
  Candidate = Struct.new(:name, :mask, :product_count, keyword_init: true) do
    def covers?(bit)
      mask.anybits?(bit)
    end

    def disjoint_from?(other_mask)
      mask.nobits?(other_mask)
    end
  end
end

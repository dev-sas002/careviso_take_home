# Selects the minimal set of packages that exactly fulfill an order (no extra products).
# Uses recursive backtracking to explore combinations and returns the one with fewest packages.
class PackageSelector
  def self.select_optimal_packages(order, available_packages)
    return nil if order.nil? || order.empty? || available_packages.nil? || available_packages.empty?
    find_optimal_combination(order, available_packages)
  end

  private

  def self.fulfill_order?(order, packages)
    products_combined = packages.flatten
    order.all? { |product| products_combined.include?(product) } && (order & products_combined).size == order.size
  end

  # Recursively finds the optimal combination of packages to fulfill an order.
  # Args:
  #   order: Array of product names to be fulfilled
  #   packages: List of available packages (each element is a Hash of package_name => product_names)
  #   current_combination: Accumulator of [package_name, product_names] pairs for current path
  # Returns:
  #   Array of package names (smallest set that exactly fulfills the order), or nil if none.
  def self.find_optimal_combination(order, packages, current_combination = [])
    current_products = current_combination.flat_map(&:last)

    # Base case: if the current combination of packages can fulfill the order without any extra products
    return [current_combination.map(&:first)] if fulfill_order?(order, current_products) && !extra_products?(order, current_products)
    # Base case: if no packages are left to consider
    return nil if packages.empty?
    
    possible_combinations = []

    packages.each_with_index do |package, index|
      package_name, package_products = package.first
      package_products = [package_products].flatten

      next_combination = current_combination + [[package_name, package_products]]

      next_products = next_combination.flat_map(&:last)

      if fulfill_order?(order, next_products) && !extra_products?(order, next_products)
        possible_combinations << next_combination.map(&:first)
      else
        combinations = find_optimal_combination(order, packages[(index + 1)..-1], next_combination)
        if combinations
          combinations = [combinations] unless combinations.first.is_a?(Array)
          possible_combinations.concat(combinations)
        end
      end
    end

    possible_combinations.min_by(&:size)
  end

  # Returns true if the combination has extra products or wrong count (not an exact match).
  def self.extra_products?(order, combination_products)
    !((combination_products - order).empty? && combination_products.length == order.length)
  end
end

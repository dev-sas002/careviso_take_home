# Everything the packaging problem needs, and nothing that knows about Rails.
#
#   Catalog             order + packages -> bitmasks, with useless packages dropped
#   Strategies::Base    the contract every selection algorithm implements
#   Registry            name -> strategy, so a new algorithm is additive
#   ShipmentForOrder    the one object in here that is allowed to touch the database
#
# `PackageSelector` (app/services/package_selector.rb) is the facade callers use.
module PackageSelection
  # Base class for every error this namespace raises.
  Error = Class.new(StandardError)

  # Raised when a strategy is asked for by a name nothing is registered under.
  UnknownStrategyError = Class.new(Error)

  # Raised when the search exceeds its configured work budget. Minimum exact
  # cover is NP-hard, so a synchronous request has to be able to give up rather
  # than tie up a Puma thread indefinitely.
  SearchLimitExceeded = Class.new(Error)
end

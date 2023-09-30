class PackageProduct < ApplicationRecord
  belongs_to :product
  belongs_to :package

  validates :product_id, uniqueness: { scope: :package_id }
end

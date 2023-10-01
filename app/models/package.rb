class Package < ApplicationRecord
  has_many :package_products, dependent: :destroy
  has_many :products, through: :package_products

  validates :name, presence: true, uniqueness: true

  # Used by the order page to show the contents of a selected shipment without
  # an N+1 on `package.products`.
  scope :named, ->(names) { includes(:products).where(name: names) }
end

class Package < ApplicationRecord
  has_many :package_products, dependent: :destroy
  has_many :products, through: :package_products

  validates :name, uniqueness: true, presence: true
end

class Package < ApplicationRecord
  has_many :package_product, dependent: :destroy
  has_many :products, through: :package_product

  validates :name, uniqueness: true, presence: true
end

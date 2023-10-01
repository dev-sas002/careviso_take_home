class Product < ApplicationRecord
  has_many :order_products, dependent: :destroy
  has_many :orders, through: :order_products
  has_many :package_products, dependent: :destroy
  has_many :packages, through: :package_products

  validates :name, presence: true, uniqueness: true
end

class Product < ApplicationRecord
  has_many :order_products
  has_many :orders, through: :order_products

  validates :name, uniqueness: true, presence: true
end

class Order < ApplicationRecord
  has_many :order_products, dependent: :destroy
  has_many :products, through: :order_products

  validates :products, presence: true

  def product_names
    products.map(&:name)
  end
end

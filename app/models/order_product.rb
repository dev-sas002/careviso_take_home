class OrderProduct < ApplicationRecord
  belongs_to :order
  belongs_to :product

  # The packaging rule is "each ordered product shipped exactly once", so a
  # duplicated join row is meaningless. The database enforces this too
  # (unique index on [order_id, product_id]); this turns the violation into a
  # validation error instead of an exception.
  validates :product_id, uniqueness: { scope: :order_id }
end

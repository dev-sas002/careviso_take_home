require 'rails_helper'

RSpec.describe Order, type: :model do
  describe "associations" do
    it { should have_many(:order_products) }
    it { should have_many(:products).through(:order_products) }
  end
end

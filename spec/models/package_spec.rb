require 'rails_helper'

RSpec.describe Package, type: :model do
  describe "associations" do
    it { should have_many(:package_product).dependent(:destroy) }
    it { should have_many(:products).through(:package_product) }
  end

  describe "validations" do
    subject { FactoryBot.create(:package) }
    it { should validate_uniqueness_of(:name) }
  end
end

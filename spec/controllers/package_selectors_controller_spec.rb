require 'rails_helper'

RSpec.describe PackageSelectorsController, type: :controller do
  describe 'POST #select_optimal_packages' do
    let(:product_a) { create(:product, name: "ProductA") }
    let(:product_b) { create(:product, name: "ProductB") }
    let(:product_c) { create(:product, name: "ProductC") }

    let!(:order) { create(:order, :with_products, products: [product_a, product_b, product_c]) }

    let!(:package1) { create(:package, :with_products, name: "Package1", products: [product_a, product_b]) }
    let!(:package2) { create(:package, :with_products, name: "Package2", products: [product_c]) }

    context 'when valid packages are found' do
      it 'returns the optimal package names' do
        post :select_optimal_packages, params: { order_id: order.id }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:success)
        expect(json_response['shipment_packages']).to match_array(["Package1", "Package2"])
      end
    end

    context 'when no valid packages are found' do
      before do
        Package.destroy_all
      end

      it 'returns an error' do
        post :select_optimal_packages, params: { order_id: order.id }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('No valid packages found')
      end
    end
  end
end

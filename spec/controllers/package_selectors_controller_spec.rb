require "rails_helper"

RSpec.describe PackageSelectorsController, type: :controller do
  describe "GET #select_optimal_packages" do
    let(:product_a) { create(:product, name: "ProductA") }
    let(:product_b) { create(:product, name: "ProductB") }
    let(:product_c) { create(:product, name: "ProductC") }

    let!(:order) { create(:order, products: [product_a, product_b, product_c]) }

    let!(:package1) { create(:package, name: "Package1", products: [product_a, product_b]) }
    let!(:package2) { create(:package, name: "Package2", products: [product_c]) }

    context "when valid packages are found" do
      it "returns the optimal package names" do
        get :select_optimal_packages, params: { order_id: order.id }
        json_response = response.parsed_body

        expect(response).to have_http_status(:success)
        expect(json_response["shipment_packages"]).to match_array(%w[Package1 Package2])
      end
    end

    context "when a smaller exact combination exists" do
      let!(:package3) do
        create(:package, name: "Package3", products: [product_a, product_b, product_c])
      end

      it "prefers the combination with the fewest packages" do
        get :select_optimal_packages, params: { order_id: order.id }
        json_response = response.parsed_body

        expect(json_response["shipment_packages"]).to eq(["Package3"])
      end
    end

    context "when packages exist but none combine to an exact match" do
      let!(:product_d) { create(:product, name: "ProductD") }
      let!(:package_with_extra) do
        create(:package, name: "PackageExtra", products: [product_a, product_b, product_c, product_d])
      end

      before { [package1, package2].each(&:destroy) }

      it "returns 404 rather than an over-filled shipment" do
        get :select_optimal_packages, params: { order_id: order.id }
        json_response = response.parsed_body

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("No valid packages found")
      end
    end

    context "when no valid packages are found" do
      before do
        Package.destroy_all
      end

      it "returns an error" do
        get :select_optimal_packages, params: { order_id: order.id }
        json_response = response.parsed_body

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("No valid packages found")
      end
    end

    context "when order_id is invalid or order does not exist" do
      it "returns 404 with error message" do
        get :select_optimal_packages, params: { order_id: 0 }
        json_response = response.parsed_body

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("Order not found")
      end
    end

    context "when the search exceeds its work budget" do
      it "returns 422 rather than holding the request open" do
        allow(PackageSelection::ShipmentForOrder)
          .to receive(:call).and_raise(PackageSelection::SearchLimitExceeded, "gave up")

        get :select_optimal_packages, params: { order_id: order.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq("Order is too large to package synchronously")
      end
    end

    context "when order_id is missing" do
      it "returns 404 with error message" do
        get :select_optimal_packages

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["error"]).to eq("Order not found")
      end
    end
  end
end

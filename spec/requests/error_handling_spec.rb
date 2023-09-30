require "rails_helper"

RSpec.describe "Error handling", type: :request do
  describe "the catch-all route" do
    it "renders the static 404 page instead of raising" do
      get "/definitely-not-a-route"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("The page you were looking for doesn")
    end

    it "handles nested unknown paths" do
      get "/orders/1/nope/nope"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "a request for a record that does not exist" do
    it "responds 404 for HTML controllers" do
      get "/orders/999999"
      expect(response).to have_http_status(:not_found)
    end

    it "responds 404 JSON for the package selector" do
      get "/select_optimal_packages", params: { order_id: 999_999 }

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to eq("Order not found")
    end
  end

  describe "the root path" do
    it "redirects to the products index" do
      get "/"
      expect(response).to redirect_to("/products")
    end
  end
end

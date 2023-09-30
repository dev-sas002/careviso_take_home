require "rails_helper"

# Controller specs do not render views, so these request specs are what stop a
# broken template from shipping. They also pin the one page that matters: the
# order page, which shows the computed shipment.
RSpec.describe "HTML pages", type: :request do
  let!(:p1) { create(:product, name: "P1") }
  let!(:p2) { create(:product, name: "P2") }
  let!(:p3) { create(:product, name: "P3") }

  let!(:package_p1_p2) { create(:package, name: "Package6", products: [p1, p2]) }
  let!(:package_p3) { create(:package, name: "Package3", products: [p3]) }
  let!(:order) { create(:order, products: [p1, p2, p3]) }

  it "renders the products index" do
    get products_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Products", "P1")
  end

  it "renders the packages index with each package's contents" do
    get packages_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Package6", "P1", "P2")
  end

  it "renders the orders index" do
    get orders_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Orders", "Show packages")
  end

  describe "the order page" do
    it "shows the computed shipment" do
      get order_path(order)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Optimal shipment", "Package6", "Package3")
      expect(response.body).to include("2 packages")
    end

    it "explains itself when no exact shipment exists" do
      package_p3.destroy

      get order_path(order)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("No exact shipment exists for this order")
    end
  end

  it "renders the new order form" do
    get new_order_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("products-select")
  end

  it "renders the new package form" do
    get new_package_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("products-select")
  end

  it "shows validation errors inline when an order has no products" do
    post orders_path, params: { order: { product_ids: [""] } }

    expect(response).to have_http_status(:success)
    expect(response.body).to include("stopped this from being saved")
  end

  it "redirects the root path to products" do
    get root_path

    expect(response).to redirect_to("/products")
  end

  it "answers the container healthcheck" do
    get "/health"

    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to eq("status" => "ok", "database" => "ok")
  end

  it "reports unhealthy when the database is unreachable" do
    allow(Order).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/health"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body["status"]).to eq("error")
  end
end

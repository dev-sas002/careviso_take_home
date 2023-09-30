require "rails_helper"

RSpec.describe OrdersController, type: :controller do
  let!(:product_a) { create(:product, name: "ProductA") }
  let!(:product_b) { create(:product, name: "ProductB") }

  describe "GET #index" do
    let!(:orders) { create_list(:order, 3) }

    it "assigns all orders to @orders" do
      get :index
      expect(assigns(:orders)).to match_array(orders)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index")
    end

    it "paginates rather than loading every order" do
      stub_const("Paginatable::DEFAULT_PER_PAGE", 2)

      get :index
      expect(assigns(:orders).size).to eq(2)
      expect(assigns(:pagination).total_pages).to eq(2)

      get :index, params: { page: 2 }
      expect(assigns(:orders).size).to eq(1)
      expect(assigns(:pagination)).to be_last_page
    end
  end

  describe "GET #show" do
    let!(:order) { create(:order) }

    it "assigns the requested order to @order" do
      get :show, params: { id: order.id }
      expect(assigns(:order)).to eq(order)
    end

    context "with the optimal shipment" do
      let!(:order) { create(:order, products: [product_a, product_b]) }

      it "computes it server-side and loads the chosen packages" do
        create(:package, name: "Both", products: [product_a, product_b])
        create(:package, name: "JustA", products: [product_a])

        get :show, params: { id: order.id }

        expect(assigns(:shipment)).to eq(%w[Both])
        expect(assigns(:shipment_packages).map(&:name)).to eq(%w[Both])
      end

      it "leaves the shipment nil when no exact combination exists" do
        create(:package, name: "OnlyA", products: [product_a])

        get :show, params: { id: order.id }

        expect(assigns(:shipment)).to be_nil
        expect(assigns(:shipment_packages)).to eq([])
      end

      it "degrades to a message when the search exceeds its budget" do
        allow(PackageSelection::ShipmentForOrder)
          .to receive(:call).and_raise(PackageSelection::SearchLimitExceeded, "too big")

        get :show, params: { id: order.id }

        expect(response).to have_http_status(:success)
        expect(assigns(:shipment_error)).to be_present
      end
    end
  end

  describe "GET #new" do
    it "assigns a new order to @order" do
      get :new
      expect(assigns(:order)).to be_a_new(Order)
    end
  end

  describe "POST #create" do
    context "with valid attributes" do
      it "creates the order and its product associations" do
        expect do
          post :create, params: { order: { product_ids: [product_a.id, product_b.id] } }
        end.to change(Order, :count).by(1)

        expect(Order.last.products).to match_array([product_a, product_b])
      end

      it "redirects to the new order" do
        post :create, params: { order: { product_ids: [product_a.id] } }
        expect(response).to redirect_to(Order.last)
      end
    end

    context "with no products selected" do
      it "does not save the new order" do
        expect do
          post :create, params: { order: { product_ids: [""] } }
        end.to_not change(Order, :count)
      end

      it "re-renders the new template with an error" do
        post :create, params: { order: { product_ids: [""] } }

        expect(response).to render_template(:new)
        expect(flash.now[:error]).to match(/Products can't be blank/)
      end
    end

    context "with missing parameters" do
      it "responds with a bad request status and error message" do
        post :create, params: {}
        json_response = response.parsed_body

        expect(response).to have_http_status(:bad_request)
        expect(json_response["error"]).to match(/param is missing or the value is empty: order/)
      end
    end
  end

  describe "GET #edit" do
    let!(:order) { create(:order) }

    it "assigns the requested order to @order" do
      get :edit, params: { id: order.id }
      expect(assigns(:order)).to eq(order)
    end
  end

  describe "PUT #update" do
    let!(:order) { create(:order, products: [product_a]) }

    context "with valid attributes" do
      it "replaces the order products" do
        put :update, params: { id: order.id, order: { product_ids: [product_b.id] } }
        expect(order.reload.products).to eq([product_b])
      end

      it "redirects to the updated order" do
        put :update, params: { id: order.id, order: { product_ids: [product_b.id] } }
        expect(response).to redirect_to(order)
      end
    end

    context "with no products selected" do
      it "does not update the order" do
        put :update, params: { id: order.id, order: { product_ids: [""] } }
        expect(order.reload.products).to eq([product_a])
      end

      it "re-renders the edit template with an error" do
        put :update, params: { id: order.id, order: { product_ids: [""] } }

        expect(response).to render_template(:edit)
        expect(flash.now[:error]).to match(/Products can't be blank/)
      end
    end

    context "with missing parameters" do
      it "responds with a bad request status and error message" do
        put :update, params: { id: order.id }
        json_response = response.parsed_body

        expect(response).to have_http_status(:bad_request)
        expect(json_response["error"]).to match(/param is missing or the value is empty: order/)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:order) { create(:order, products: [product_a, product_b]) }

    it "deletes the order and its join records" do
      expect do
        delete :destroy, params: { id: order.id }
      end.to change(Order, :count).by(-1).and change(OrderProduct, :count).by(-2)
    end

    it "leaves the products themselves alone" do
      delete :destroy, params: { id: order.id }
      expect(Product.where(id: [product_a.id, product_b.id]).count).to eq(2)
    end

    it "redirects to orders#index" do
      delete :destroy, params: { id: order.id }
      expect(response).to redirect_to(orders_path)
    end
  end

  describe "a missing order" do
    it "renders the 404 page instead of raising" do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(:not_found)
    end
  end
end

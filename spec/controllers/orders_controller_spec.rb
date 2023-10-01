require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let(:product_a) { create(:product, name: "ProductA") }
  let(:product_b) { create(:product, name: "ProductB") }

  describe 'GET #index' do
    let!(:orders) { create_list(:order, 3) }

    it 'assigns all orders to @orders' do
      get :index
      expect(assigns(:orders)).to match_array(orders)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end
  end

  describe 'GET #show' do
    let!(:order) { create(:order) }

    it 'assigns the requested order to @order' do
      get :show, params: { id: order.id }
      expect(assigns(:order)).to eq(order)
    end
  end

  describe 'GET #new' do
    it 'assigns a new order to @order' do
      get :new
      expect(assigns(:order)).to be_a_new(Order)
    end
  end

  describe 'POST #create' do
    context 'with invalid attributes' do
      it 'does not save the new order' do
        expect {
          post :create, params: { order: { product_ids: [] } }
        }.to_not change(Order, :count)
      end

      it 'responds with a bad request status and error message' do
        post :create, params: {}
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']).to match(/param is missing or the value is empty: order/)
      end
    end
  end

  describe 'GET #edit' do
    let!(:order) { create(:order) }

    it 'assigns the requested order to @order' do
      get :edit, params: { id: order.id }
      expect(assigns(:order)).to eq(order)
    end
  end

  describe 'PUT #update' do
    let!(:order) { create(:order) }

    context 'with invalid attributes' do
      it 'does not update the order' do
        put :update, params: { id: order.id, order: { product_ids: [] } }
        order.reload
        expect(order.products).to be_empty
      end

      it 'responds with a bad request status and error message' do
        put :update, params: { id: order.id }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']).to match(/param is missing or the value is empty: order/)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:order) { create(:order) }

    it 'deletes the order' do
      expect {
        delete :destroy, params: { id: order.id }
      }.to change(Order, :count).by(-1)
    end

    it 'redirects to orders#index' do
      delete :destroy, params: { id: order.id }
      expect(response).to redirect_to(orders_path)
    end
  end
end

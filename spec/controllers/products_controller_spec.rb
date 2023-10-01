require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
  let(:valid_attributes) { { name: 'SampleProduct' } }
  let(:invalid_attributes) { { name: '' } }

  describe 'GET #index' do
    it 'assigns all products to @products' do
      product = Product.create! valid_attributes
      get :index
      expect(assigns(:products)).to eq([product])
    end
  end

  describe 'GET #show' do
    it 'assigns the requested product to @product' do
      product = Product.create! valid_attributes
      get :show, params: { id: product.id }
      expect(assigns(:product)).to eq(product)
    end
  end

  describe 'GET #new' do
    it 'assigns a new product to @product' do
      get :new
      expect(assigns(:product)).to be_a_new(Product)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new product' do
        expect {
          post :create, params: { product: valid_attributes }
        }.to change(Product, :count).by(1)
      end

      it 'redirects to the new product' do
        post :create, params: { product: valid_attributes }
        expect(response).to redirect_to(Product.last)
      end
    end

    context 'with invalid attributes' do
      it 'does not save the new product' do
        expect {
          post :create, params: { product: invalid_attributes }
        }.to_not change(Product, :count)
      end

      it 're-renders the new template' do
        post :create, params: { product: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end

    context 'with missing parameters' do
      it 'responds with a bad request status and error message' do
        post :create, params: {}
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']).to match(/param is missing or the value is empty: product/)
      end
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested product to @product' do
      product = Product.create! valid_attributes
      get :edit, params: { id: product.id }
      expect(assigns(:product)).to eq(product)
    end
  end

  describe 'PUT #update' do
    let!(:product) { Product.create! valid_attributes }

    context 'with valid attributes' do
      it 'updates the product' do
        put :update, params: { id: product.id, product: { name: "UpdatedProduct" } }
        product.reload
        expect(product.name).to eq("UpdatedProduct")
      end

      it 'redirects to the updated product' do
        put :update, params: { id: product.id, product: { name: "UpdatedProduct" } }
        expect(response).to redirect_to(product)
      end
    end

    context 'with invalid attributes' do
      it 'does not update the product' do
        put :update, params: { id: product.id, product: invalid_attributes }
        product.reload
        expect(product.name).not_to eq("")
      end

      it 're-renders the edit template' do
        put :update, params: { id: product.id, product: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end

    context 'with missing parameters' do
      it 'responds with a bad request status and error message' do
        put :update, params: { id: product.id }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']).to match(/param is missing or the value is empty: product/)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:product) { Product.create! valid_attributes }

    it 'deletes the product' do
      expect {
        delete :destroy, params: { id: product.id }
      }.to change(Product, :count).by(-1)
    end

    it 'redirects to products#index' do
      delete :destroy, params: { id: product.id }
      expect(response).to redirect_to(products_path)
    end
  end
end

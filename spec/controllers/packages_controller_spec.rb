require 'rails_helper'

RSpec.describe PackagesController, type: :controller do
  let(:valid_attributes) { { name: 'SamplePackage' } }
  let(:invalid_attributes) { { name: '' } }

  describe 'GET #index' do
    it 'assigns all packages to @packages' do
      package = Package.create! valid_attributes
      get :index
      expect(assigns(:packages)).to eq([package])
    end
  end

  describe 'GET #show' do
    it 'assigns the requested package to @package' do
      package = Package.create! valid_attributes
      get :show, params: { id: package.id }
      expect(assigns(:package)).to eq(package)
    end
  end

  describe 'GET #new' do
    it 'assigns a new package to @package' do
      get :new
      expect(assigns(:package)).to be_a_new(Package)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new package' do
        expect {
          post :create, params: { package: valid_attributes }
        }.to change(Package, :count).by(1)
      end

      it 'redirects to the new package' do
        post :create, params: { package: valid_attributes }
        expect(response).to redirect_to(Package.last)
      end
    end

    context 'with invalid attributes' do
      it 'does not save the new package' do
        expect {
          post :create, params: { package: invalid_attributes }
        }.to_not change(Package, :count)
      end

      it 're-renders the new template' do
        post :create, params: { package: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end

    context 'with missing parameters' do
      it 'responds with a bad request status and error message' do
        post :create, params: {}
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']).to match(/param is missing or the value is empty: package/)
      end
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested package to @package' do
      package = Package.create! valid_attributes
      get :edit, params: { id: package.id }
      expect(assigns(:package)).to eq(package)
    end
  end

  describe 'PUT #update' do
    let!(:package) { Package.create! valid_attributes }

    context 'with valid attributes' do
      it 'updates the package' do
        put :update, params: { id: package.id, package: { name: "UpdatedPackage" } }
        package.reload
        expect(package.name).to eq("UpdatedPackage")
      end

      it 'redirects to the updated package' do
        put :update, params: { id: package.id, package: { name: "UpdatedPackage" } }
        expect(response).to redirect_to(package)
      end
    end

    context 'with invalid attributes' do
      it 'does not update the package' do
        original_name = package.name
        put :update, params: { id: package.id, package: invalid_attributes }
        package.reload
        expect(package.name).to eq(original_name)
      end

      it 're-renders the edit template' do
        put :update, params: { id: package.id, package: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end

    context 'with missing parameters' do
      it 'responds with a bad request status and error message' do
        put :update, params: { id: package.id }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']).to match(/param is missing or the value is empty: package/)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:package) { Package.create! valid_attributes }

    it 'deletes the package' do
      expect {
        delete :destroy, params: { id: package.id }
      }.to change(Package, :count).by(-1)
    end

    it 'redirects to packages#index' do
      delete :destroy, params: { id: package.id }
      expect(response).to redirect_to(packages_path)
    end
  end
end

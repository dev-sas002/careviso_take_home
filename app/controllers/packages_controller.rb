class PackagesController < ApplicationController
  before_action :find_package, only: %i[show edit update destroy]
  # The forms offer every product; loading them here keeps `Product.all` out of the view.
  before_action :load_available_products, only: %i[new create edit update]

  def index
    # `includes` keeps the index at two queries no matter how many packages
    # are on the page; the view lists each package's products.
    @packages = paginate(Package.includes(:products).order(:name))
  end

  def show; end

  def new
    @package = Package.new
  end

  def edit; end

  def create
    @package = Package.new(package_params)
    if @package.save
      flash[:success] = "Package was successfully created."
      redirect_to @package
    else
      flash.now[:error] = @package.errors.full_messages.to_sentence
      render :new
    end
  end

  def update
    if @package.update(package_params)
      flash[:success] = "Package was successfully updated."
      redirect_to @package
    else
      flash.now[:error] = @package.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    @package.destroy
    redirect_to packages_path
  end

  private

  def load_available_products
    @available_products = Product.order(:name)
  end

  def find_package
    @package = Package.find(params[:id])
  end

  def package_params
    params.require(:package).permit(:name, product_ids: [])
  end
end

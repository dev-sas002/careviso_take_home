class PackagesController < ApplicationController
  before_action :find_package, only: [:show, :edit, :update, :destroy]

  def index
    @packages = Package.all
  end

  def show
  end

  def new
    @package = Package.new
  end

  def create
    @package = Package.new(package_params)
    if @package.save
      flash[:success] = 'Package was successfully created.'
      redirect_to @package
    else
      flash.now[:error] = @package.errors.full_messages.to_sentence
      render :new
    end
  end

  def edit
  end

  def update
    if @package.update(package_params)
      flash[:success] = 'Package was successfully updated.'
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

  def find_package
    @package = Package.find(params[:id])
  end

  def package_params
    params.require(:package).permit(:name ,product_ids: [])
  end
end

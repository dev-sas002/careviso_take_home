class OrdersController < ApplicationController
  before_action :find_order, only: %i[show edit update destroy]
  # The forms offer every product; loading them here keeps `Product.all` out of the view.
  before_action :load_available_products, only: %i[new create edit update]

  def index
    @orders = paginate(Order.includes(:products).order(id: :desc))
  end

  # The order page answers the question the exercise is about, server-side:
  # which packages ship this order exactly. The JSON endpoint
  # (`/select_optimal_packages`) serves the same answer to the index page's modal.
  def show
    @shipment = PackageSelection::ShipmentForOrder.call(@order)
    @shipment_packages = @shipment ? Package.named(@shipment).sort_by { |package| @shipment.index(package.name) } : []
  rescue PackageSelection::SearchLimitExceeded => e
    Rails.logger.warn("[package_selection] #{e.message}")
    @shipment_error = "This order has too many products to package in a single request."
  end

  def new
    @order = Order.new
  end

  def edit; end

  def create
    @order = Order.new(order_params)
    if @order.save
      flash[:success] = "Order was successfully created."
      redirect_to @order
    else
      flash.now[:error] = @order.errors.full_messages.to_sentence
      render :new
    end
  end

  def update
    if @order.update(order_params)
      flash[:success] = "Order was successfully updated."
      redirect_to @order
    else
      flash.now[:error] = @order.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_path
  end

  private

  def load_available_products
    @available_products = Product.order(:name)
  end

  def find_order
    @order = Order.includes(:products).find(params[:id])
  end

  def order_params
    params.require(:order).permit(product_ids: [])
  end
end

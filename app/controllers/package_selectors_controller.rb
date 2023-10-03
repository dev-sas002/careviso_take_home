class PackageSelectorsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :order_not_found

  def select_optimal_packages
    shipment = PackageSelector.select_optimal_packages(order_products, available_packages)

    if shipment && shipment.any?
      render json: { shipment_packages: shipment }
    else
      render json: { error: 'No valid packages found' }, status: :not_found
    end
  end

  private

  def order
    @order ||= Order.find(params[:order_id])
  end

  def order_products
    @order_products ||= order.products.pluck(:name)
  end

  def available_packages
    @available_packages ||= Package.all.map do |package|
      { package.name => package.products.pluck(:name) }
    end
  end

  def order_not_found
    render json: { error: 'Order not found' }, status: :not_found
  end
end
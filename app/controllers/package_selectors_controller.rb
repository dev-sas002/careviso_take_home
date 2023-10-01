class PackageSelectorsController < ApplicationController

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
end
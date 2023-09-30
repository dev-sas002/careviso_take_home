# JSON endpoint for the packaging problem: GET /select_optimal_packages?order_id=1
#
# Thin by design — find the order, ask the domain, render. Everything
# interesting lives in PackageSelection.
class PackageSelectorsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :order_not_found
  rescue_from PackageSelection::SearchLimitExceeded, with: :search_too_large

  def select_optimal_packages
    shipment = PackageSelection::ShipmentForOrder.call(order)

    if shipment.present?
      render json: { shipment_packages: shipment }
    else
      render json: { error: "No valid packages found" }, status: :not_found
    end
  end

  private

  def order
    @order ||= Order.find(params[:order_id])
  end

  def order_not_found
    render json: { error: "Order not found" }, status: :not_found
  end

  def search_too_large(error)
    Rails.logger.warn("[package_selection] #{error.message}")
    render json: { error: "Order is too large to package synchronously" }, status: :unprocessable_entity
  end
end

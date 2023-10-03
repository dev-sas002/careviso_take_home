# Liveness probe for the container healthcheck. Cheap, unauthenticated, and it
# actually touches the database so that "up" means "can serve a request".
class HealthController < ApplicationController
  def show
    Order.connection.select_value("SELECT 1")
    render json: { status: "ok", database: "ok" }
  rescue StandardError => e
    Rails.logger.error("[health] #{e.class}: #{e.message}")
    render json: { status: "error", database: e.class.name }, status: :service_unavailable
  end
end

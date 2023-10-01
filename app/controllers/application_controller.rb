class ApplicationController < ActionController::Base
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  private

  def parameter_missing(e)
    render json: { error: e.message }, status: :bad_request
  end

  def not_found
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end
end

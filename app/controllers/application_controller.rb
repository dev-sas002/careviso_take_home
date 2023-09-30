class ApplicationController < ActionController::Base
  include Paginatable

  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  # Public so that the catch-all route in config/routes.rb
  # (`match '*path', to: 'application#not_found'`) can dispatch to it.
  # Rails only treats public instance methods as controller actions.
  def not_found(_exception = nil)
    render file: Rails.public_path.join("404.html").to_s,
           layout: false,
           status: :not_found
  end

  private

  def parameter_missing(error)
    render json: { error: error.message }, status: :bad_request
  end
end

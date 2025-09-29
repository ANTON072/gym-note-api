class ApplicationController < ActionController::API
  include Authenticatable

  rescue_from ActionController::UnpermittedParameters do |exception|
    render json: { error: "Invalid parameters: #{exception.params.join(', ')}" },
           status: :bad_request
  end
end

class ApplicationController < ActionController::API
  include Authenticatable

  rescue_from ActionController::UnpermittedParameters do |exception|
    render json: { error: I18n.t("errors.invalid_parameters", params: exception.params.join(", ")) },
           status: :bad_request
  end
end

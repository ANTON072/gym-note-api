# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

web_local_origin = "http://localhost:5173"
web_production_origin = "https://gym-note.net"

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 環境に応じて許可するオリジンを設定
    allowed_origins = case Rails.env
    when "development"
      [ web_local_origin ]
    when "production"
      [ web_production_origin, web_local_origin ]
    else
      [ web_local_origin ]
    end

    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true  # 認証情報（Cookie等）を含むリクエストを許可
  end
end

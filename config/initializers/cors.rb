# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 環境に応じて許可するオリジンを設定
    allowed_origins = case Rails.env
    when "development"
      [ "http://localhost:3001", "http://localhost:3000" ]
    when "production"
      # TODO: 本番環境のフロントエンドURLに置き換える
      [ "https://app.example.com" ]
    else
      [ "http://localhost:3001" ]
    end

    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true  # 認証情報（Cookie等）を含むリクエストを許可
  end
end

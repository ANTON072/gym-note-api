module Authenticatable
  extend ActiveSupport::Concern

  private

  # Authorizationヘッダーからトークンを抽出する
  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil if auth_header.blank?

    # "Bearer token" 形式からtokenを抽出
    match = auth_header.match(/\ABearer (.+)\z/)
    return nil unless match

    match[1]
  end

  # Firebase AuthServiceを使ってトークンを検証する
  def verify_token(token)
    Firebase::AuthService.verify_id_token(token, firebase_project_id)
  rescue JWT::VerificationError => e
    Rails.logger.warn "Token verification failed: #{e.message}"
    nil
  end

  # Firebase プロジェクトIDを環境変数から取得する
  def firebase_project_id
    ENV["FIREBASE_PROJECT_ID"] || raise(
      Rails::Configuration::ConfigurationError,
      "FIREBASE_PROJECT_ID environment variable is not set. " \
      "Please set FIREBASE_PROJECT_ID in your environment configuration " \
      "(e.g., in .env or your deployment environment) to enable Firebase authentication."
    )
  end

  # 認証を必須とするアクションで使用する
  def authenticate_user!
    token = extract_token_from_header
    if token.nil?
      return render json: { error: "Authentication required" }, status: :unauthorized
    end

    payload = verify_token(token)
    if payload.nil?
      return render json: { error: "Invalid token" }, status: :unauthorized
    end

    @current_user = find_or_create_user_from_payload(payload)
  end

  # 現在のユーザーを取得する
  def current_user
    @current_user
  end

  # Firebase payloadからユーザーを検索または作成する
  def find_or_create_user_from_payload(payload)
    firebase_uid = payload["sub"]
    user = User.find_by(firebase_uid: firebase_uid)

    # Payloadデータを安全な属性に変換
    user_attributes = build_user_attributes_from_payload(payload)

    if user
      # 既存ユーザーの情報を最新に更新
      user.update!(user_attributes)
      user
    else
      # 新規ユーザー作成
      User.create!(user_attributes.merge(firebase_uid: firebase_uid))
    end
  end

  # Firebase payloadから安全なユーザー属性を構築する
  def build_user_attributes_from_payload(payload)
    {
      email: sanitize_email(payload["email"]),
      name: sanitize_name(payload["name"]),
      image_url: sanitize_image_url(payload["picture"])
    }
  end

  # メールアドレスのサニタイズ
  def sanitize_email(email)
    return nil if email.blank?
    email.to_s.strip.downcase
  end

  # 名前のサニタイズ
  def sanitize_name(name)
    return nil if name.blank?
    name.to_s.strip
  end

  # 画像URLのサニタイズ
  def sanitize_image_url(image_url)
    return nil if image_url.blank?
    # HTTPSまたはHTTPで始まるURLのみ許可
    url = image_url.to_s.strip
    url.match?(/\Ahttps?:\/\/.+/) ? url : nil
  end
end

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
    ENV["FIREBASE_PROJECT_ID"] || raise("FIREBASE_PROJECT_ID environment variable is not set")
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

    if user
      # 既存ユーザーの情報を最新に更新
      user.update!(
        email: payload["email"],
        name: payload["name"],
        image_url: payload["picture"]
      )
      user
    else
      # 新規ユーザー作成
      User.create!(
        firebase_uid: firebase_uid,
        email: payload["email"],
        name: payload["name"],
        image_url: payload["picture"]
      )
    end
  end
end
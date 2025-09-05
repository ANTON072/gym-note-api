require "test_helper"
require "jwt"
require "openssl"
require "net/http"

class Firebase::AuthServiceTest < ActiveSupport::TestCase
  setup do
    @project_id = "test-project-id"
    @user_id = "test-user-123"
    @email = "test@example.com"
    
    # テスト用のRSA鍵ペアを生成
    @rsa_private = OpenSSL::PKey::RSA.generate(2048)
    @rsa_public = @rsa_private.public_key
    
    # モック用の証明書を作成
    @certificate = create_test_certificate(@rsa_public)
    
    # 公開鍵取得のスタブ
    stub_public_keys_request
  end
  
  teardown do
    # キャッシュをクリア
    Firebase::AuthService.instance_variable_set(:@public_keys_cache, nil)
    Firebase::AuthService.instance_variable_set(:@cache_expires_at, nil)
  end
  
  test "正しいトークンの検証に成功する" do
    token = create_valid_token
    
    payload = Firebase::AuthService.verify_id_token(token, @project_id)
    
    assert_equal @user_id, payload["sub"]
    assert_equal @email, payload["email"]
    assert_equal @project_id, payload["aud"]
  end
  
  test "期限切れトークンの検証に失敗する" do
    token = create_expired_token
    
    assert_raises(JWT::VerificationError) do
      Firebase::AuthService.verify_id_token(token, @project_id)
    end
  end
  
  test "不正な署名のトークンの検証に失敗する" do
    # 別の鍵で署名されたトークン
    other_key = OpenSSL::PKey::RSA.generate(2048)
    token = create_token_with_key(other_key)
    
    assert_raises(JWT::VerificationError) do
      Firebase::AuthService.verify_id_token(token, @project_id)
    end
  end
  
  test "不正な発行者のトークンの検証に失敗する" do
    token = create_token(iss: "https://invalid-issuer.com/#{@project_id}")
    
    assert_raises(JWT::VerificationError) do
      Firebase::AuthService.verify_id_token(token, @project_id)
    end
  end
  
  test "不正なaudienceのトークンの検証に失敗する" do
    token = create_token(aud: "wrong-project-id")
    
    assert_raises(JWT::VerificationError) do
      Firebase::AuthService.verify_id_token(token, @project_id)
    end
  end
  
  test "auth_timeが未来の時刻の場合に失敗する" do
    token = create_token(auth_time: Time.now.to_i + 3600)
    
    assert_raises(JWT::VerificationError) do
      Firebase::AuthService.verify_id_token(token, @project_id)
    end
  end
  
  test "subjectが空の場合に失敗する" do
    token = create_token(sub: "")
    
    assert_raises(JWT::VerificationError) do
      Firebase::AuthService.verify_id_token(token, @project_id)
    end
  end
  
  test "トークンがnilの場合にエラーを発生させる" do
    assert_raises(ArgumentError) do
      Firebase::AuthService.verify_id_token(nil, @project_id)
    end
  end
  
  test "プロジェクトIDがnilの場合にエラーを発生させる" do
    token = create_valid_token
    
    assert_raises(ArgumentError) do
      Firebase::AuthService.verify_id_token(token, nil)
    end
  end
  
  test "公開鍵がキャッシュされる" do
    # 最初のリクエスト
    token1 = create_valid_token
    Firebase::AuthService.verify_id_token(token1, @project_id)
    
    # 2回目のリクエスト（キャッシュから取得される）
    token2 = create_valid_token
    
    # HTTPリクエストが1回しか呼ばれないことを確認
    Net::HTTP.expects(:get_response).never
    
    Firebase::AuthService.verify_id_token(token2, @project_id)
  end
  
  private
  
  def create_valid_token
    create_token
  end
  
  def create_expired_token
    create_token(
      exp: Time.now.to_i - 3600,  # 1時間前
      iat: Time.now.to_i - 7200   # 2時間前
    )
  end
  
  def create_token(options = {})
    create_token_with_key(@rsa_private, options)
  end
  
  def create_token_with_key(key, options = {})
    now = Time.now.to_i
    
    payload = {
      "iss" => options[:iss] || "https://securetoken.google.com/#{@project_id}",
      "aud" => options[:aud] || @project_id,
      "auth_time" => options[:auth_time] || now - 60,
      "user_id" => @user_id,
      "sub" => options.key?(:sub) ? options[:sub] : @user_id,
      "iat" => options[:iat] || now,
      "exp" => options[:exp] || now + 3600,
      "email" => @email,
      "email_verified" => true,
      "firebase" => {
        "identities" => {
          "google.com" => [@user_id],
          "email" => [@email]
        },
        "sign_in_provider" => "google.com"
      }
    }
    
    JWT.encode(payload, key, "RS256", { "kid" => "test-key-id" })
  end
  
  def create_test_certificate(public_key)
    # テスト用の証明書を作成
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = OpenSSL::X509::Name.parse("CN=Test")
    cert.issuer = cert.subject
    cert.public_key = public_key
    cert.not_before = Time.now
    cert.not_after = cert.not_before + 365 * 24 * 60 * 60 # 1年後
    
    # 自己署名
    cert.sign(@rsa_private, OpenSSL::Digest::SHA256.new)
    
    cert.to_pem
  end
  
  def stub_public_keys_request
    response_body = {
      "test-key-id" => @certificate
    }.to_json
    
    response = stub(
      body: response_body,
      "[]" => "max-age=3600",
      is_a?: true
    )
    
    Net::HTTP.stubs(:get_response).returns(response)
  end
end
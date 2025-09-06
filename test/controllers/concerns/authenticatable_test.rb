require "test_helper"

class AuthenticatableTest < ActiveSupport::TestCase
  class TestController < ActionController::API
    include Authenticatable
    attr_accessor :request

    def initialize
      super
      self.request = MockRequest.new
    end
  end

  class MockRequest
    attr_accessor :headers

    def initialize
      @headers = {}
    end
  end

  setup do
    @controller = TestController.new
    # テスト用のFirebaseプロジェクトID
    @project_id = "test-project"
    ENV["FIREBASE_PROJECT_ID"] = @project_id
  end

  test "Authorizationヘッダーからトークンを抽出できること" do
    @controller.request.headers["Authorization"] = "Bearer valid.jwt.token"

    assert_equal "valid.jwt.token", @controller.send(:extract_token_from_header)
  end

  test "Authorizationヘッダーがない場合はnilを返すこと" do
    assert_nil @controller.send(:extract_token_from_header)
  end

  test "Authorizationヘッダーの形式が間違っている場合はnilを返すこと" do
    @controller.request.headers["Authorization"] = "InvalidFormat"
    assert_nil @controller.send(:extract_token_from_header)
  end

  test "有効なトークンを検証してユーザーペイロードを返すこと" do
    token = "valid.jwt.token"
    payload = {
      "sub" => "firebase_uid_123",
      "email" => "test@example.com",
      "name" => "Test User",
      "picture" => "https://example.com/avatar.jpg"
    }

    Firebase::AuthService.stubs(:verify_id_token).with(token, @project_id).returns(payload)

    result = @controller.send(:verify_token, token)
    assert_equal payload, result
  end

  test "無効なトークンの場合はnilを返すこと" do
    token = "invalid.jwt.token"

    Firebase::AuthService.stubs(:verify_id_token).with(token, @project_id).raises(JWT::VerificationError.new("Invalid token"))

    assert_nil @controller.send(:verify_token, token)
  end

  test "トークンがない場合にauthenticate_user!が401レスポンスを返すこと" do
    mock_response = { error: "Authentication required" }
    @controller.expects(:render).with(json: mock_response, status: :unauthorized)

    @controller.send(:authenticate_user!)
  end

  test "無効なトークンの場合にauthenticate_user!が401レスポンスを返すこと" do
    @controller.request.headers["Authorization"] = "Bearer invalid.token"

    Firebase::AuthService.stubs(:verify_id_token).raises(JWT::VerificationError.new("Invalid token"))

    mock_response = { error: "Invalid token" }
    @controller.expects(:render).with(json: mock_response, status: :unauthorized)

    @controller.send(:authenticate_user!)
  end

  test "有効なトークンでユーザーを作成または更新すること" do
    user = users(:one)
    token = "valid.token"
    payload = {
      "sub" => user.firebase_uid,
      "email" => "updated@example.com",
      "name" => "Updated User",
      "picture" => "https://example.com/new-avatar.jpg"
    }

    @controller.request.headers["Authorization"] = "Bearer #{token}"
    Firebase::AuthService.stubs(:verify_id_token).with(token, @project_id).returns(payload)

    @controller.send(:authenticate_user!)

    # ユーザー情報が更新されていることを確認
    user.reload
    assert_equal "updated@example.com", user.email
    assert_equal "Updated User", user.name
    assert_equal "https://example.com/new-avatar.jpg", user.image_url

    # current_userが設定されていることを確認
    assert_equal user, @controller.send(:current_user)
  end
end

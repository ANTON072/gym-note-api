require "test_helper"

class AuthenticatableTest < ActionController::TestCase
  class TestController < ActionController::API
    include Authenticatable

    def index
      render json: { message: "success" }
    end

    def protected_action
      authenticate_user!
      render json: { user_id: current_user.id }
    end
  end

  def setup
    @controller = TestController.new
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "test", to: "authenticatable_test/test#index"
      get "protected", to: "authenticatable_test/test#protected_action"
    end
    @controller.instance_variable_set(:@_routes, @routes)

    # テスト用のFirebaseプロジェクトID
    @project_id = "test-project"
    allow_any_instance_of(TestController).to receive(:firebase_project_id).and_return(@project_id)
  end

  test "Authorizationヘッダーからトークンを抽出できること" do
    token = "Bearer valid.jwt.token"
    @request.headers["Authorization"] = token

    assert_equal "valid.jwt.token", @controller.send(:extract_token_from_header)
  end

  test "Authorizationヘッダーがない場合はnilを返すこと" do
    assert_nil @controller.send(:extract_token_from_header)
  end

  test "Authorizationヘッダーの形式が間違っている場合はnilを返すこと" do
    @request.headers["Authorization"] = "InvalidFormat"
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

    Firebase::AuthService.expects(:verify_id_token).with(token, @project_id).returns(payload)

    result = @controller.send(:verify_token, token)
    assert_equal payload, result
  end

  test "無効なトークンの場合はnilを返すこと" do
    token = "invalid.jwt.token"

    Firebase::AuthService.expects(:verify_id_token).with(token, @project_id).raises(JWT::VerificationError.new("Invalid token"))

    assert_nil @controller.send(:verify_token, token)
  end

  test "authenticate_user!はトークンがない場合401を返すこと" do
    get :protected_action
    assert_response :unauthorized
    assert_equal({ "error" => "Authentication required" }, JSON.parse(response.body))
  end

  test "authenticate_user!は無効なトークンの場合401を返すこと" do
    @request.headers["Authorization"] = "Bearer invalid.token"

    Firebase::AuthService.expects(:verify_id_token).raises(JWT::VerificationError.new("Invalid token"))

    get :protected_action
    assert_response :unauthorized
    assert_equal({ "error" => "Invalid token" }, JSON.parse(response.body))
  end

  test "authenticate_user!は有効なトークンと既存ユーザーで成功すること" do
    user = users(:one)  # fixture from users.yml
    token = "valid.token"
    payload = {
      "sub" => user.firebase_uid,
      "email" => user.email,
      "name" => user.name,
      "picture" => user.image_url
    }

    @request.headers["Authorization"] = "Bearer #{token}"

    Firebase::AuthService.expects(:verify_id_token).with(token, @project_id).returns(payload)

    get :protected_action
    assert_response :success
    assert_equal({ "user_id" => user.id }, JSON.parse(response.body))
  end
end

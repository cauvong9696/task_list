require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:alice) }

  test "new renders the sign-in form" do
    get login_url
    assert_response :success
    assert_select "h1", "Sign in"
  end

  test "signs in with valid credentials" do
    post login_url, params: { email: @user.email, password: "password" }
    assert_redirected_to tasks_url
    follow_redirect!
    assert_select ".account-bar", /#{Regexp.escape(@user.email)}/
  end

  test "signing in is case-insensitive on email" do
    post login_url, params: { email: @user.email.upcase, password: "password" }
    assert_redirected_to tasks_url
  end

  test "rejects invalid credentials" do
    post login_url, params: { email: @user.email, password: "wrong" }
    assert_response :unprocessable_entity
    get tasks_url
    assert_redirected_to login_url
  end

  test "signs out" do
    post login_url, params: { email: @user.email, password: "password" }
    delete logout_url
    assert_redirected_to login_url
    get tasks_url
    assert_redirected_to login_url
  end
end

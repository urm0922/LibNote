require "test_helper"

class UserRegistrationsTest < ActionDispatch::IntegrationTest
  test "request to register as admin is declined." do
    email = "requested-admin@example.com"

    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          name: "管理者希望ユーザー",
          email: email,
          password: "password",
          password_confirmation: "password",
          role: "admin"
        }
      }
    end

    registered_user = User.find_by!(email: email)

    assert_equal "staff", registered_user.role
    assert_not registered_user.admin?
  end
end
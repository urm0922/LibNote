require "test_helper"

class UserTest < ActiveSupport::TestCase

  test "nameがあれば有効" do
    user = User.new(
      name: "ユーザー1",
      role: "staff",
      email: "user1@example.com",
      password: "password"
    )

    assert user.valid?
  end
  
  test "nameがなければ無効" do
    user = User.new(
      role: "staff",
      email: "user1@example.com",
      password: "password"
    )

    assert_not user.valid?
  end
  
  test "roleが無効な値の場合は無効" do
    assert_raises(ArgumentError) do
      User.new(role: "invalid")
    end
  end
  
  test "default_roleはstaff" do
    user = User.new(
      name: "ユーザー1"
    )

    assert_equal "staff", user.role
  end
end

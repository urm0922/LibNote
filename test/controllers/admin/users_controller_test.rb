require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "admin can view user index" do
    sign_in users(:admin)
    get admin_users_path
    
    assert_response :success
    assert_includes response.body, users(:staff).name
    assert_not_includes response.body, users(:deleted_staff).name
  end

  test "staff cannot access user index" do
    sign_in users(:staff)
    get admin_users_path

    assert_redirected_to root_path
  end
  
  test "admin can update user's information" do
    sign_in users(:admin)
    user = users(:staff)

    patch admin_user_path(user), params: {
      user: {
        name: "Changed_name",
        email: "changed.email@example.com",
        role: "manager"
      }
    }

    assert_redirected_to admin_users_path
    assert_equal "Changed_name", user.reload.name
    assert_equal "changed.email@example.com", user.email
    assert_equal "manager", user.role

  end

  test "admin can patch user's activate deactive" do
    sign_in users(:admin)
    user = users(:staff)

    patch deactivate_admin_user_path(user)

    assert_redirected_to edit_admin_user_path(user)
    assert_equal false, user.reload.active
  end

  test "admin can patch user's activate active" do
    sign_in users(:admin)
    user = users(:deactive_staff)

    patch activate_admin_user_path(user)

    assert_redirected_to edit_admin_user_path(user)
    assert_equal true, user.reload.active
  end

  test "staff cannot update user's information" do
    sign_in users(:staff)
    user = users(:other_staff)
    patch admin_user_path(user), params: {
      user: {
        name: "Changed_name",
        email: "changed.email@example.com",
        role: "manager"
      }
    }

    assert_redirected_to root_path
    assert_not_equal "Changed_name", user.reload.name
    assert_not_equal "changed.email@example.com", user.email
    assert_not_equal "manager", user.role

  end
      
  test "staff cannot patch user's active status" do
    sign_in users(:staff)
    user = users(:manager)
    
    patch deactivate_admin_user_path(user)
    
    assert_redirected_to root_path
    assert_equal true, user.reload.active
  end

  test "admin cannot change own role" do
    sign_in users(:admin)
    user = users(:admin)
    patch admin_user_path(user), params: {
      user: {
        role: "manager"
      }
    }

    assert_response :unprocessable_entity
    assert_equal "admin", user.reload.role

  end

  test "cannot change admin's role who is last admin" do
    sign_in users(:admin)
    user = users(:admin2)
    patch admin_user_path(user), params: {
      user: {
        role: "manager"
      }
    }

    assert_equal "manager", user.reload.role

    patch admin_user_path(users(:admin)), params: {
      user: {
        role: "staff"
      }
    }

    assert_response :unprocessable_entity
    assert_equal "admin", users(:admin).reload.role

  end

  test "admin cannot own activate deactive " do
    sign_in users(:admin)
    user = users(:admin)
    patch deactivate_admin_user_path(user)

    assert_redirected_to edit_admin_user_path(user)
    assert_equal true, user.reload.active
  end

  test "admin can demote other admin and cannot deactive admin who is last active admin" do
    sign_in users(:admin)
    user = users(:admin2)
    patch admin_user_path(user), params: {
      user: {
        role: "manager"
      }
    }

    assert_equal "manager", user.reload.role

    patch deactivate_admin_user_path(users(:admin))

    assert_redirected_to edit_admin_user_path(users(:admin))
    assert_equal true, users(:admin).reload.active

  end

  test "admin can search user by keyword" do
    sign_in users(:admin)
    get admin_users_path, params: {
      q: "指導"
    }
    
    assert_response :success
    assert_includes response.body, users(:manager).name
    assert_not_includes response.body, users(:staff).name
  end

  test "admin can search user by email" do
    sign_in users(:admin)
    get admin_users_path, params: {
      eq: "admin2"
    }
    
    assert_response :success
    assert_includes response.body, users(:admin2).name
    assert_not_includes response.body, users(:staff).name
  end

  test "admin can search user by active status" do
    sign_in users(:admin)
    get admin_users_path, params: {
      active: "false"
    }
    
    assert_response :success
    assert_includes response.body, users(:deactive_staff).name
    assert_not_includes response.body, users(:staff).name
  end

  test "admin can search user by role" do
    sign_in users(:admin)
    get admin_users_path, params: {
      role: "manager"
    }

    assert_includes response.body, users(:manager).name
    assert_not_includes response.body, users(:staff).name
  end

  test "admin cannot activate deleted user" do
    sign_in users(:admin)
    user = users(:deleted_staff)
    patch activate_admin_user_path(user)

    assert_response :not_found
    assert_equal false, user.reload.active
  end

  test "admin cannot change own role but name and email" do
    sign_in users(:admin)
    user = users(:admin)
    patch admin_user_path(user), params: {
      user: {
        name: "Changed_admin_name",
        email: "changed.admin@example.com"
      }
    }

    assert_equal "Changed_admin_name", user.reload.name
    assert_equal "changed.admin@example.com", user.reload.email
  end
end
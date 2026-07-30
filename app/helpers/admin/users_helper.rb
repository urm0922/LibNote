module Admin::UsersHelper
    def user_role_label(user)
        {
          "admin" => "管理者",
          "manager" => "マネージャー",
          "staff" => "スタッフ",
        }.fetch(user.role, user.role)
      end
    
      def user_role_class(user)
        "role-#{user.role}"
      end  
end

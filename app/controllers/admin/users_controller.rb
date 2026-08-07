class Admin::UsersController < Admin::BaseController
  before_action :set_user, except: :index
  def index
    @users = User.not_deleted
                .search_keyword(params[:q])
                .search_email_keyword(params[:eq])
                .by_role(params[:role])
                .by_active(params[:active])
                .order(created_at: :desc)
                .page(params[:page])
  end

  def edit
  end

  def update
    requested_role = user_params[:role]

    role_will_change =
      requested_role.present? && requested_role != @user.role
      
    if role_will_change && role_change_or_deactivation_forbidden?
      @user.assign_attributes(user_params.except(:role))
      @user.errors.add(:role, "このユーザーの役割は変更できません")
      
      return render :edit, status: :unprocessable_entity
    end

    if @user.update(user_params)
      redirect_to admin_users_path, notice: "ユーザー情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def activate
      if @user.activate_user
        redirect_to edit_admin_user_path(@user), notice: "ユーザー状態を「利用中」に設定しました"
      else
        render :edit, status: :unprocessable_entity
      end
  end

  def deactivate
    unless role_change_or_deactivation_forbidden?
      if @user.deactivate_user
        redirect_to edit_admin_user_path(@user), notice: "ユーザー状態を「停止中」に設定しました"
      else
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to edit_admin_user_path(@user), alert: "このユーザーは停止することができません"
    end
  end
  
  private

  def set_user
    @user = User.not_deleted
                .find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end

  def role_change_or_deactivation_forbidden?
    current_user == @user || last_active_admin?(@user)
  end

  def last_active_admin?(user)
    user.admin? &&
      user.active? &&
      user.deleted_at.nil? &&
      User.active_users.admin.where.not(id: user.id).none?
  end


end

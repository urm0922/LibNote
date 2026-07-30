class Admin::UsersController < ApplicationController
  def index
    @users = User.search_keyword(params[:q])
                 .by_role(params[:role])
                 .page(params[:page]).order(created_at: :desc)
  end

  def edit
    @user = User.find(params[:id])

  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "ユーザー情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def activate
  end

  def deactivate
  end
  
  private

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end


end

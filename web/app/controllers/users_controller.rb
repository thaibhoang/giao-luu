# frozen_string_literal: true

class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  before_action :set_user, only: %i[show edit update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Tạo tài khoản thành công."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, status: :see_other, notice: "Cập nhật hồ sơ thành công."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
    redirect_to new_session_path if @user.nil?
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def profile_params
    params.require(:user).permit(
      :display_name, :phone_number, :date_of_birth, :gender,
      :address, :bio, :sport_badminton, :sport_pickleball,
      :skill_level_badminton, :skill_level_pickleball
    )
  end
end

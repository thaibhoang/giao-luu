# frozen_string_literal: true

class RegistrationsController < ApplicationController
  before_action :set_listing
  before_action :require_login, only: %i[checkin confirm]
  before_action :require_owner, only: %i[index confirm]

  # GET /listings/:listing_id/registrations — chỉ chủ bài xem
  def index
    @registrations = @listing.registrations.includes(:user)
  end

  # POST /listings/:listing_id/registrations
  def create
    @registration = @listing.registrations.build(registration_params)
    @registration.user = Current.session.user

    if @registration.save
      redirect_to @listing, notice: "Đăng ký tham gia thành công!"
    else
      redirect_to @listing, alert: @registration.errors.full_messages.first
    end
  end

  # DELETE /listings/:listing_id/registrations/:id
  def destroy
    @registration = @listing.registrations.find_by(user: Current.session.user)
    if @registration&.destroy
      redirect_to @listing, notice: "Đã huỷ đăng ký."
    else
      redirect_to @listing, alert: "Không tìm thấy đăng ký của bạn."
    end
  end

  # PUT /listings/:listing_id/registrations/:id/checkin — người tham gia tự check-in
  def checkin
    @registration = @listing.registrations.find_by!(user: Current.session.user)
    if @registration.checkin!
      redirect_to @listing, notice: "Đã check-in thành công! 🎉"
    else
      redirect_to @listing, alert: "Không thể check-in lúc này (chưa kết thúc hoặc đã check-in rồi)."
    end
  end

  # PUT /listings/:listing_id/registrations/:id/confirm — chủ listing xác nhận
  def confirm
    @registration = @listing.registrations.find(params[:id])
    if @registration.owner_confirm!
      redirect_to listing_registrations_path(@listing), notice: "Đã xác nhận tham dự."
    else
      redirect_to listing_registrations_path(@listing), alert: "Không thể xác nhận lúc này."
    end
  end

  private

    def set_listing
      @listing = Listing.find(params[:listing_id])
    end

    def registration_params
      params.require(:registration).permit(:note, :phone)
    end

    def require_owner
      unless Current.session.user == @listing.user
        redirect_to @listing, alert: "Bạn không có quyền xem danh sách này."
      end
    end

    def require_login
      unless Current.session&.user
        redirect_to new_session_path, alert: "Vui lòng đăng nhập."
      end
    end
end

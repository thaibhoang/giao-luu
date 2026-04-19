# frozen_string_literal: true

module Admin
  class FacebookImportsController < Admin::ApplicationController
    def new
    end

    def create
      raw_post = params[:raw_post].to_s.strip
      contact_fb_link = params[:contact_fb_link].to_s.strip

      if raw_post.blank?
        flash.now[:alert] = "Vui lòng dán nội dung bài viết."
        render :new, status: :unprocessable_entity and return
      end

      result = Admin::FacebookExtractService.call(raw_post: raw_post, contact_fb_link: contact_fb_link)

      if result.success?
        @extracted = result.data
        @raw_post = raw_post
        @contact_fb_link = contact_fb_link
        render :review
      else
        flash.now[:alert] = "Không thể phân tích bài viết: #{result.error}"
        @raw_post = raw_post
        @contact_fb_link = contact_fb_link
        render :new, status: :unprocessable_entity
      end
    end

    def confirm
      listing_params = params.require(:listing).permit(
        :sport, :title, :body, :location_name,
        :start_at, :end_at, :slots_needed,
        :skill_level_min, :skill_level_max,
        :price_estimate, :contact_info, :source_url
      )

      attributes = listing_params.to_h.merge(source: Listing::SOURCE_FACEBOOK_SCRAPE, schema_version: 3)
      attributes[:source_url] = nil if attributes[:source_url].blank?

      # Validate trước khi geocode để tránh gọi API khi dữ liệu sai
      listing = Listing.new(attributes)
      unless listing.valid?
        flash.now[:alert] = "Lỗi khi lưu: #{listing.errors.full_messages.join(', ')}"
        @extracted = listing_params
        render :review, status: :unprocessable_entity and return
      end

      # Geocode location_name → lấy kinh độ/vĩ độ
      geo = Geocoding::LookupService.call(query: listing_params[:location_name])

      if geo[:ok]
        listing = Listing.insert_with_point!(
          attributes,
          longitude: geo[:data][:lng],
          latitude:  geo[:data][:lat]
        )
        geocode_notice = geo[:data][:from_cache] ? " (toạ độ từ cache)" : " (geocode: #{geo[:data][:display_name]})"
        redirect_to admin_dashboard_path,
                    notice: "Đã lưu listing thành công: \"#{listing.title}\".#{geocode_notice}"
      else
        # Geocode thất bại → vẫn lưu nhưng geom = nil, cảnh báo admin
        Rails.logger.warn("admin_import_geocode_failed location=#{listing_params[:location_name].inspect} error=#{geo[:error]}")
        listing.save!
        redirect_to admin_dashboard_path,
                    notice: "Đã lưu listing \"#{listing.title}\" nhưng chưa có toạ độ (#{geo[:error]}). Cập nhật địa điểm sau để hiện trên bản đồ."
      end
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "Lỗi khi lưu: #{e.record.errors.full_messages.join(', ')}"
      @extracted = listing_params
      render :review, status: :unprocessable_entity
    end
  end
end

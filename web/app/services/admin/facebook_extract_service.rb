# frozen_string_literal: true

module Admin
  # Gọi OpenAI để extract thông tin listing từ nội dung bài Facebook.
  # Trả về OpenStruct với .success?, .data (hash), .error (string).
  class FacebookExtractService
    SYSTEM_PROMPT_TEMPLATE = <<~PROMPT
      Bạn là trợ lý AI phân tích bài đăng tìm đối cầu lông / pickleball từ Facebook.
      Từ nội dung người dùng cung cấp, hãy trả về JSON thuần (không markdown, không giải thích)
      với đúng các trường sau:

      - sport: "badminton" hoặc "pickleball"
      - title: tiêu đề ngắn gọn (tối đa 100 ký tự) mô tả tin tuyển
      - body: mô tả đầy đủ (copy gọn lại từ bài gốc, tối đa 1000 ký tự)
      - location_name: tên sân hoặc địa chỉ đầy đủ để geocode
      - start_time: chỉ trích xuất THÁNG và NGÀY từ bài viết, định dạng "--MM-DDTHH:MM:00+07:00"
        (ví dụ: "--10-30T09:00:00+07:00"). KHÔNG tự suy đoán năm — hệ thống sẽ tự điền năm %<current_year>d.
      - end_time: tương tự start_time. Nếu không có thông tin, ước tính 2 tiếng sau start_time.
      - slots_needed: số người/slot cần (integer >= 1). Nếu không rõ, dùng 1.
      - skill_level_min: một trong [yeu, trung_binh_yeu, trung_binh_minus, trung_binh, trung_binh_plus, trung_binh_plus_plus, trung_binh_kha, kha, ban_chuyen, chuyen_nghiep]
      - skill_level_max: tương tự, phải >= skill_level_min
      - price_estimate: ước tính VND/người (integer), null nếu không đề cập
      - contact_info: thông tin liên hệ nếu có trong bài (không bao gồm SĐT/email cá nhân, ưu tiên link)

      Trả về JSON object, không bọc trong markdown.
    PROMPT

    Result = Data.define(:success, :data, :error) do
      def success? = success
    end

    def self.call(raw_post:, contact_fb_link: nil)
      new(raw_post: raw_post, contact_fb_link: contact_fb_link).call
    end

    def initialize(raw_post:, contact_fb_link: nil)
      @raw_post = raw_post
      @contact_fb_link = contact_fb_link
    end

    def call
      client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
      system_prompt = format(SYSTEM_PROMPT_TEMPLATE, current_year: Time.current.year)

      response = client.chat(
        parameters: {
          model: ENV.fetch("OPENAI_EXTRACT_MODEL", "gpt-4o-mini"),
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: @raw_post }
          ],
          temperature: 0.2,
          response_format: { type: "json_object" }
        }
      )

      content = response.dig("choices", 0, "message", "content")
      raise "OpenAI trả về rỗng" if content.blank?

      data = JSON.parse(content)
      data = normalize(data)

      Result.new(success: true, data: data, error: nil)
    rescue => e
      Rails.logger.error("[Admin::FacebookExtractService] #{e.class}: #{e.message}")
      Result.new(success: false, data: nil, error: e.message)
    end

    private

      def normalize(data)
        # Override contact_info bằng link FB admin đã cung cấp
        data["contact_info"] = @contact_fb_link if @contact_fb_link.present?

        # Đổi key start_time / end_time → start_at / end_at cho Listing
        data["start_at"] = data.delete("start_time") if data.key?("start_time")
        data["end_at"]   = data.delete("end_time")   if data.key?("end_time")

        # AI trả về dạng "--MM-DDTHH:MM:SS+07:00" (không có năm) → inject năm hiện tại
        current_year = Time.current.year
        %w[start_at end_at].each do |field|
          next if data[field].blank?

          data[field] = data[field].to_s.sub(/\A--/, "#{current_year}-")
        end

        data
      end
  end
end

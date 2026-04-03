# frozen_string_literal: true

# Seed listings có geom cố định để kiểm map / ST_DWithin (docs/DATA_MODEL.md).
return unless ActiveRecord::Base.connection.table_exists?("listings")
return unless ActiveRecord::Base.connection.extension_enabled?("postgis")
return unless ActiveRecord::Base.connection.table_exists?("users")

now = Time.current

demo_user = User.find_or_initialize_by(email_address: "demo@example.com")
if demo_user.new_record?
  demo_user.password = "password"
  demo_user.password_confirmation = "password"
  demo_user.save!
end

unless Listing.exists?(title: "Seed: giao lưu HCM")
  Listing.insert_with_point!(
    {
      sport: "badminton",
      title: "Seed: giao lưu HCM",
      body: "Bản ghi thử từ db:seed",
      location_name: "Trung tâm Quận 1 (seed)",
      start_at: now + 1.day,
      end_at: now + 1.day + 2.hours,
      slots_needed: 2,
      skill_level_min: "trung_binh",
      skill_level_max: "trung_binh_plus",
      price_estimate: 50_000,
      contact_info: "https://example.com/seed-hcm",
      source: "user_submitted",
      source_url: nil,
      schema_version: 3,
      user_id: demo_user.id
    },
    longitude: 106.6297,
    latitude: 10.8231
  )
end

unless Listing.exists?(title: "Seed: pickleball Hà Nội")
  Listing.insert_with_point!(
    {
      sport: "pickleball",
      title: "Seed: pickleball Hà Nội",
      location_name: "Công viên (seed)",
      start_at: now + 2.days,
      end_at: now + 2.days + 3.hours,
      slots_needed: 3,
      skill_level_min: "trung_binh_yeu",
      skill_level_max: "trung_binh_kha",
      price_estimate: nil,
      contact_info: "https://example.com/seed-hn",
      source: "user_submitted",
      source_url: nil,
      schema_version: 3,
      user_id: demo_user.id
    },
    longitude: 105.8342,
    latitude: 21.0278
  )
end

cache_key = "sân 583 nguyễn trãi, hồ chí minh"
unless GeocodingCache.exists?(location_query: cache_key)
  GeocodingCache.insert_with_point!(
    location_query: cache_key,
    provider: "google",
    raw_response: nil,
    longitude: 106.6297,
    latitude: 10.8231
  )
end

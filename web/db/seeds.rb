# frozen_string_literal: true

# --- Seed Admin ---
if ActiveRecord::Base.connection.table_exists?("admin_users")
  admin_email    = ENV.fetch("ADMIN_EMAIL")
  admin_password = ENV.fetch("ADMIN_PASSWORD")

  admin = AdminUser.find_or_initialize_by(email_address: admin_email)
  if admin.new_record?
    admin.password = admin_password
    admin.password_confirmation = admin_password
    admin.save!
    puts "✅ Admin created: #{admin_email}"
  else
    puts "ℹ️  Admin already exists: #{admin_email}"
  end
end

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

10.times do |i|
  unless Listing.exists?(title: "Seed: Pickleball Sân #{i + 1}")
    Listing.insert_with_point!(
     {
       sport: "pickleball",
       title: "Seed: Pickleball Sân #{i + 1}",
       body: "Bản ghi thử từ db:seed cho sân #{i + 1}",
       location_name: "Sân #{i + 1} (seed)",
       start_at: now + (i + 1).days,
       end_at: now + (i + 1).days + 1.hour,
       slots_needed: i % 4 + 2,
       skill_level_min: "trung_binh_yeu",
       skill_level_max: "trung_binh_kha",
       price_estimate: (i + 1) * 20_000,
       contact_info: "https://example.com/seed-tennis-#{i + 1}",
       source: "user_submitted",
       source_url: nil,
       schema_version: 3,
       user_id: demo_user.id
     },
     longitude: 106.6297 + i * 0.001,
     latitude: 10.8231 + i * 0.001
   )
  end
end

10.times do |i|
   unless Listing.exists?(title: "Seed: Badminton Sân #{i + 1}")
     Listing.insert_with_point!(
       {
         sport: "badminton",
         title: "Seed: Badminton Sân #{i + 1}",
         body: "Bản ghi thử từ db:seed cho sân cầu lông #{i + 1}",
         location_name: "Sân cầu lông #{i + 1} (seed)",
         start_at: now + (i + 1).days,
         end_at: now + (i + 1).days + 2.hours,
         slots_needed: i % 4 + 2,
         skill_level_min: "trung_binh_yeu",
         skill_level_max: "trung_binh_kha",
         price_estimate: (i + 1) * 15_000,
         contact_info: "https://example.com/seed-badminton-#{i + 1}",
         source: "user_submitted",
         source_url: nil,
         schema_version: 3,
         user_id: demo_user.id
       },
       longitude: 105.8342 - i * 0.001,
       latitude: 21.0278 - i * 0.001
     )
   end
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

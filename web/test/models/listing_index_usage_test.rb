# frozen_string_literal: true

require "test_helper"

# Kiểm tra EXPLAIN để xác nhận partial index được planner PostgreSQL sử dụng.
# Chỉ chạy được khi có PostgreSQL + PostGIS.
class ListingIndexUsageTest < ActiveSupport::TestCase
  self.use_transactional_tests = true
  fixtures :users

  setup do
    @conn = ActiveRecord::Base.connection
    skip "Cần PostgreSQL + PostGIS" unless pg_with_postgis?
    # ANALYZE để planner có statistics
    @conn.execute("ANALYZE listings")
  end

  def pg_with_postgis?
    @conn.adapter_name.casecmp("postgresql").zero? && @conn.extension_enabled?("postgis")
  end

  # Tắt seq scan để buộc planner dùng index nếu phù hợp — cách chuẩn để verify index tồn tại và usable
  def explain_force_index(rel)
    @conn.execute("SET enable_seqscan = off")
    result = @conn.execute("EXPLAIN #{rel.to_sql}").map { |r| r["QUERY PLAN"] }.join("\n")
    @conn.execute("SET enable_seqscan = on")
    result
  end

  test "query active + sport + start_at dùng idx_listings_active_sport_start" do
    plan = explain_force_index(
      Listing.where(active: true, sport: "badminton")
             .where("start_at >= ?", Time.current)
             .order(start_at: :asc)
    )
    assert_match "idx_listings_active_sport_start", plan,
      "Planner không dùng idx_listings_active_sport_start!\nPlan:\n#{plan}"
  end

  test "query active + listing_type + start_at dùng idx_listings_active_type_start" do
    plan = explain_force_index(
      Listing.where(active: true, listing_type: "match_finding")
             .where("start_at >= ?", Time.current)
             .order(start_at: :asc)
    )
    assert_match "idx_listings_active_type_start", plan,
      "Planner không dùng idx_listings_active_type_start!\nPlan:\n#{plan}"
  end

  test "scope upcoming dùng partial index (active + start_at)" do
    plan = explain_force_index(Listing.upcoming)
    has_partial_index = plan.include?("idx_listings_active_sport_start") ||
                        plan.include?("idx_listings_active_type_start")
    assert has_partial_index,
      "Planner không dùng partial index nào!\nPlan:\n#{plan}"
  end
end

# frozen_string_literal: true

# Job tái generate (invalidate cache) sitemap khi có listing mới được tạo.
#
# Với approach render on-the-fly hiện tại, job thực hiện:
# 1. Xoá Solid Cache entry của sitemap nếu có (khi sau này bật fragment cache).
# 2. Log để monitoring biết sitemap đã được trigger.
#
# Nếu sau này chuyển sang cache file ra disk (public/sitemap.xml), implement
# logic write file tại đây.
class GenerateSitemapJob < ApplicationJob
  queue_as :default

  def perform
    # Xóa cache key sitemap nếu đang dùng fragment/Rails cache
    Rails.cache.delete("sitemap_xml") if Rails.cache.exist?("sitemap_xml")

    Rails.logger.info("GenerateSitemapJob: sitemap cache invalidated at #{Time.current.iso8601}")
  end
end

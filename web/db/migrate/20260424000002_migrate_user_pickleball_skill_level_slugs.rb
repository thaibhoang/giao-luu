# frozen_string_literal: true

class MigrateUserPickleballSkillLevelSlugs < ActiveRecord::Migration[8.0]
  SLUG_MAP = {
    "2.0-2.5" => "dupr_2_0",
    "2.5-3.0" => "dupr_2_5",
    "3.0-3.5" => "dupr_3_0",
    "3.5-4.0" => "dupr_3_5",
    "4.0-4.5" => "dupr_4_0",
    "4.5-5.0" => "dupr_4_5",
    "5.0+"    => "dupr_5_0"
  }.freeze

  def up
    SLUG_MAP.each do |old_slug, new_slug|
      execute <<~SQL
        UPDATE users SET skill_level_pickleball = '#{new_slug}'
        WHERE skill_level_pickleball = '#{old_slug}'
      SQL
    end
  end

  def down
    SLUG_MAP.each do |old_slug, new_slug|
      execute <<~SQL
        UPDATE users SET skill_level_pickleball = '#{old_slug}'
        WHERE skill_level_pickleball = '#{new_slug}'
      SQL
    end
  end
end

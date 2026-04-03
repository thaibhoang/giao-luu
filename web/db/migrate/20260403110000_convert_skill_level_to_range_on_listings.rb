# frozen_string_literal: true

class ConvertSkillLevelToRangeOnListings < ActiveRecord::Migration[8.1]
  SKILL_LEVELS = %w[
    yeu
    trung_binh_yeu
    trung_binh_minus
    trung_binh
    trung_binh_plus
    trung_binh_plus_plus
    trung_binh_kha
    kha
    ban_chuyen
    chuyen_nghiep
  ].freeze

  def up
    add_column :listings, :skill_level_min, :string
    add_column :listings, :skill_level_max, :string

    execute <<~SQL.squish
      UPDATE listings
      SET skill_level_min = skill_level, skill_level_max = skill_level
    SQL

    change_column_null :listings, :skill_level_min, false
    change_column_null :listings, :skill_level_max, false

    remove_check_constraint :listings, name: "listings_skill_level_valid"

    levels_sql = SKILL_LEVELS.map { |s| "'#{s}'" }.join(", ")
    ordered_levels_sql = "ARRAY[#{levels_sql}]::text[]"

    add_check_constraint :listings,
                         "skill_level_min IN (#{levels_sql})",
                         name: "listings_skill_level_min_valid"
    add_check_constraint :listings,
                         "skill_level_max IN (#{levels_sql})",
                         name: "listings_skill_level_max_valid"
    add_check_constraint :listings,
                         "array_position(#{ordered_levels_sql}, skill_level_min::text) <= "\
                         "array_position(#{ordered_levels_sql}, skill_level_max::text)",
                         name: "listings_skill_level_range_valid"

    remove_column :listings, :skill_level, :string
  end

  def down
    add_column :listings, :skill_level, :string

    execute <<~SQL.squish
      UPDATE listings
      SET skill_level = skill_level_min
    SQL

    change_column_null :listings, :skill_level, false

    remove_check_constraint :listings, name: "listings_skill_level_range_valid"
    remove_check_constraint :listings, name: "listings_skill_level_max_valid"
    remove_check_constraint :listings, name: "listings_skill_level_min_valid"

    levels_sql = SKILL_LEVELS.map { |s| "'#{s}'" }.join(", ")
    add_check_constraint :listings,
                         "skill_level IN (#{levels_sql})",
                         name: "listings_skill_level_valid"

    remove_column :listings, :skill_level_max, :string
    remove_column :listings, :skill_level_min, :string
  end
end

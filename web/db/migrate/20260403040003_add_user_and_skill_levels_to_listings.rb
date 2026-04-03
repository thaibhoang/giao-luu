# frozen_string_literal: true

class AddUserAndSkillLevelsToListings < ActiveRecord::Migration[8.1]
  NEW_SKILL_LEVELS = %w[
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
    add_reference :listings, :user, null: true, foreign_key: true

    remove_check_constraint :listings, name: "listings_skill_level_valid"

    execute <<~SQL.squish
      UPDATE listings SET skill_level = CASE skill_level
        WHEN 'beginner' THEN 'yeu'
        WHEN 'beginner-intermediate' THEN 'trung_binh_yeu'
        WHEN 'intermediate' THEN 'trung_binh'
        WHEN 'intermediate-advanced' THEN 'kha'
        WHEN 'advanced' THEN 'chuyen_nghiep'
        ELSE skill_level
      END
    SQL

    levels_sql = NEW_SKILL_LEVELS.map { |s| "'#{s}'" }.join(", ")
    add_check_constraint :listings,
                         "skill_level IN (#{levels_sql})",
                         name: "listings_skill_level_valid"
  end

  def down
    remove_check_constraint :listings, name: "listings_skill_level_valid"

    execute <<~SQL.squish
      UPDATE listings SET skill_level = CASE skill_level
        WHEN 'yeu' THEN 'beginner'
        WHEN 'trung_binh_yeu' THEN 'beginner-intermediate'
        WHEN 'trung_binh_minus' THEN 'beginner-intermediate'
        WHEN 'trung_binh' THEN 'intermediate'
        WHEN 'trung_binh_plus' THEN 'intermediate'
        WHEN 'trung_binh_plus_plus' THEN 'intermediate-advanced'
        WHEN 'trung_binh_kha' THEN 'intermediate-advanced'
        WHEN 'kha' THEN 'intermediate-advanced'
        WHEN 'ban_chuyen' THEN 'advanced'
        WHEN 'chuyen_nghiep' THEN 'advanced'
        ELSE skill_level
      END
    SQL

    add_check_constraint :listings,
                         "skill_level IN ('beginner', 'beginner-intermediate', 'intermediate', 'intermediate-advanced', 'advanced')",
                         name: "listings_skill_level_valid"

    remove_reference :listings, :user, foreign_key: true
  end
end

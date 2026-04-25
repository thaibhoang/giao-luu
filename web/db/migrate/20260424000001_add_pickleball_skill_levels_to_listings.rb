# frozen_string_literal: true

class AddPickleballSkillLevelsToListings < ActiveRecord::Migration[8.0]
  DUPR_SLUGS = %w[dupr_2_0 dupr_2_5 dupr_3_0 dupr_3_5 dupr_4_0 dupr_4_5 dupr_5_0].freeze
  SLUG_ARRAY = DUPR_SLUGS.map { |s| "'#{s}'" }.join(", ")

  def up
    add_column :listings, :skill_level_min_pk, :string
    add_column :listings, :skill_level_max_pk, :string

    execute <<~SQL
      ALTER TABLE listings
        ADD CONSTRAINT listings_skill_level_min_pk_valid
          CHECK (skill_level_min_pk IS NULL OR skill_level_min_pk = ANY (ARRAY[#{SLUG_ARRAY}]));
    SQL

    execute <<~SQL
      ALTER TABLE listings
        ADD CONSTRAINT listings_skill_level_max_pk_valid
          CHECK (skill_level_max_pk IS NULL OR skill_level_max_pk = ANY (ARRAY[#{SLUG_ARRAY}]));
    SQL

    execute <<~SQL
      ALTER TABLE listings
        ADD CONSTRAINT listings_skill_level_pk_range_valid
          CHECK (
            skill_level_min_pk IS NULL OR skill_level_max_pk IS NULL OR
            array_position(ARRAY[#{SLUG_ARRAY}], skill_level_min_pk) <=
            array_position(ARRAY[#{SLUG_ARRAY}], skill_level_max_pk)
          );
    SQL
  end

  def down
    remove_check_constraint :listings, name: "listings_skill_level_pk_range_valid"
    remove_check_constraint :listings, name: "listings_skill_level_max_pk_valid"
    remove_check_constraint :listings, name: "listings_skill_level_min_pk_valid"
    remove_column :listings, :skill_level_max_pk
    remove_column :listings, :skill_level_min_pk
  end
end

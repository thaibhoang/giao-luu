# frozen_string_literal: true

class AddGenderRequirementToListings < ActiveRecord::Migration[8.0]
  def change
    add_column :listings, :gender_requirement, :string
    add_index  :listings, :gender_requirement
  end
end

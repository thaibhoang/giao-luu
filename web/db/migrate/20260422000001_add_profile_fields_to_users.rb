# frozen_string_literal: true

class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :display_name, :string
    add_column :users, :phone_number, :string
    add_column :users, :date_of_birth, :date
    add_column :users, :gender, :string
    add_column :users, :address, :string
    add_column :users, :bio, :text
    add_column :users, :sport_badminton, :boolean, default: false, null: false
    add_column :users, :sport_pickleball, :boolean, default: false, null: false
    add_column :users, :skill_level_badminton, :string
    add_column :users, :skill_level_pickleball, :string
  end
end

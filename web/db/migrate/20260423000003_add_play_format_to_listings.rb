# frozen_string_literal: true

class AddPlayFormatToListings < ActiveRecord::Migration[8.0]
  def change
    add_column :listings, :play_format, :string
    add_index  :listings, :play_format
  end
end

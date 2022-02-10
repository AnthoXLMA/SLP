# frozen_string_literal: true

class DropCountryFromTours < ActiveRecord::Migration[6.1]
  def change
    remove_column :tours, :country, :string, limit: 2
    add_reference :tours, :country, foreign_key: true
  end
end

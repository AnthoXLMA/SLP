# frozen_string_literal: true

class AddFieldsToTours < ActiveRecord::Migration[6.1]
  def change
    add_column :tours, :country, :string, limit: 2
    add_column :tours, :short_description, :string
  end
end

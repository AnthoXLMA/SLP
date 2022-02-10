# frozen_string_literal: true

class ModifyColumnNotNull < ActiveRecord::Migration[6.1]
  def change
    default_short_description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.'
    default_description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\nUt enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
    default_location = 'Paris'

    change_column_null :guide_infos, :short_description, false, default_short_description
    change_column_null :guide_infos, :description, false, default_description
    change_column_null :guide_infos, :location, false, default_location

    change_column_null :tours, :title, false, 'title'
    change_column_null :tours, :subtitle, false, 'subtitle'
    change_column_null :tours, :short_description, false, default_short_description
    change_column_null :tours, :description, false, default_description
    change_column_null :tours, :country_id, false, Country.first&.id
    remove_column :tours, :guide, :string
    remove_column :tours, :next_date, :date

    change_column_null :countries, :country, false
    change_column_null :countries, :region, false
    change_column_null :countries, :code, false, '--'
  end
end

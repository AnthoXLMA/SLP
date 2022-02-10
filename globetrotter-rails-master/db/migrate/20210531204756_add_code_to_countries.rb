# frozen_string_literal: true

class AddCodeToCountries < ActiveRecord::Migration[6.1]
  def change
    add_column :countries, :code, :string, limit: 2
  end
end

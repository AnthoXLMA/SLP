# frozen_string_literal: true

class CreateCountries < ActiveRecord::Migration[6.1]
  def change
    create_table :countries do |t|
      t.string :country
      t.string :region

      t.timestamps
      t.index %i[region country], unique: true
    end
  end
end

# frozen_string_literal: true

class CreateTourGuides < ActiveRecord::Migration[6.1]
  def change
    create_table :tour_guides do |t|
      t.references :tour, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.index %i[tour_id user_id], unique: true
      t.timestamps
    end
  end
end

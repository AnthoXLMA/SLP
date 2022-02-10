# frozen_string_literal: true

class CreateGuideInfo < ActiveRecord::Migration[6.1]
  def change
    create_table :guide_infos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :description
      t.string :short_description
      t.string :location
      t.string :topics
      t.float :rating

      t.timestamps
    end
  end
end

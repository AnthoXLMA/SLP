# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.references :tour_guide, null: false, foreign_key: true
      t.timestamp :date

      t.timestamps
    end
    add_index :events, %i[tour_guide_id date], unique: true
  end
end

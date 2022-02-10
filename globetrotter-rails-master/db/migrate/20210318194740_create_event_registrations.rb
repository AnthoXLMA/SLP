# frozen_string_literal: true

class CreateEventRegistrations < ActiveRecord::Migration[6.1]
  def change
    create_table :event_registrations do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
      t.index %i[event_id user_id], unique: true
    end
  end
end

# frozen_string_literal: true

class AddZoomToEvent < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :zoom_meeting_details, :jsonb
  end
end

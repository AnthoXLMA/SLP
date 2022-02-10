class CreateNextEvents < ActiveRecord::Migration[6.1]
  def change
    execute <<~SQL
      CREATE MATERIALIZED VIEW next_events AS
      SELECT id, date, zoom_meeting_details, tour_id, zoom_license_id, license_tsrange, guide_id
      FROM (
        SELECT events.*, row_number() over (partition by tour_id order by date) as row_number
        FROM events
        WHERE date > now()
      ) sub
      WHERE sub.row_number = 1
    SQL
    add_index :next_events, :id, unique: true
    remove_index :events, :tour_id
    add_index :events, %i[tour_id date]
    add_index :next_events, %i[tour_id date]
  end
end

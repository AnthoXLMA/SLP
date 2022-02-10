class UpdateNextEvents < ActiveRecord::Migration[6.1]
  def change
    execute <<~SQL
      DROP MATERIALIZED VIEW next_events CASCADE;
      CREATE MATERIALIZED VIEW next_events AS
      SELECT id, date, zoom_meeting_details, tour_id, zoom_license_id, license_tsrange, guide_id
      FROM (
        SELECT events.*, row_number() over (partition by tour_id order by date) as row_number
        FROM events
        WHERE date > now() and cancelled_date is null
      ) sub
      WHERE sub.row_number = 1
    SQL
    add_index :next_events, :id, unique: true
    add_index :next_events, %i[tour_id date]
  end
end

class CreateZoomLicenses < ActiveRecord::Migration[6.1]
  def change
    execute 'CREATE EXTENSION btree_gist'
    create_table :zoom_licenses do |t|
      t.string :zoom_user_id

      t.timestamps
    end
    add_reference :events, :zoom_license, foreign_key: true
    add_column :events, :license_tsrange, :tsrange
    execute <<~SQL
      update events
      set license_tsrange = tsrange(date - interval '#{Event::LIVE_BEFORE_EVENT_IN_MINUTES} minutes', date + interval '1 hour')
    SQL

    execute <<~SQL
      alter table events
      add constraint unique_license
      exclude using gist(
        license_tsrange with &&,
        zoom_license_id with =
      )
    SQL

    add_column :tours, :duration, :interval
    change_column_null :tours, :duration, false, 45.minutes

    add_reference :guides, :zoom_license, foreign_key: true
  end
end

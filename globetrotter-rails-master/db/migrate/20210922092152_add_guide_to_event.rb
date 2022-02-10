class AddGuideToEvent < ActiveRecord::Migration[6.1]
  def change
    add_reference :events, :guide, foreign_key: true
    execute <<~SQL
      alter table events
      add constraint guide_availability
      exclude using gist(
        license_tsrange with &&,
        guide_id with =
      )
    SQL
  end
end

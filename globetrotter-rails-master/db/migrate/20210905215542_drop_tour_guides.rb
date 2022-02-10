# frozen_string_literal: true

class DropTourGuides < ActiveRecord::Migration[6.1]
  def change
    change_table :tours do |t|
      t.references :guide_info
    end
    execute <<~SQL
      update tours
      set guide_info_id = sub.guide_info_id from (
        select guide_infos.id as guide_info_id, tour_guides.tour_id from guide_infos
        join tour_guides on tour_guides.user_id = guide_infos.user_id ) sub
      where sub.tour_id = tours.id
    SQL
    change_column_null :tours, :guide_info_id, false

    remove_foreign_key :tour_guides, :tours
    remove_foreign_key :tour_guides, :users

    change_table :events do |t|
      t.references :tour
    end
    execute <<~SQL
      update events
      set tour_id = tour_guides.tour_id
      from tour_guides
      where tour_guides.id = tour_guide_id
    SQL
    change_column_null :events, :tour_id, false

    remove_foreign_key :events, :tour_guides
    remove_column :events, :tour_guide_id

    drop_table :tour_guides
  end
end

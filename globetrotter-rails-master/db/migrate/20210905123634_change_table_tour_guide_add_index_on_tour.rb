# frozen_string_literal: true

class ChangeTableTourGuideAddIndexOnTour < ActiveRecord::Migration[6.1]
  def change
    execute <<~SQL
      delete from tour_guides
      where tour_id in (
        select tour_id from tour_guides group by tour_id having count(*) > 1
      )
    SQL
    remove_index :tour_guides, :tour_id
    add_index :tour_guides, :tour_id, unique: true
  end
end

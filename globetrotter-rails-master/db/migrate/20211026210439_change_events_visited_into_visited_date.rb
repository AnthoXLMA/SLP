class ChangeEventsVisitedIntoVisitedDate < ActiveRecord::Migration[6.1]
  def change
    remove_column :event_registrations, :visited, :boolean
    add_column :event_registrations, :visited_date, :timestamp
  end
end

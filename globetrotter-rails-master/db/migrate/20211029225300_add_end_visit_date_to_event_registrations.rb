class AddEndVisitDateToEventRegistrations < ActiveRecord::Migration[6.1]
  def change
    add_column :event_registrations, :end_visit_date, :timestamp
  end
end

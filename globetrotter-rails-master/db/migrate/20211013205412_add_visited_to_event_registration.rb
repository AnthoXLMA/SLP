class AddVisitedToEventRegistration < ActiveRecord::Migration[6.1]
  def change
    add_column :event_registrations, :visited, :boolean, default: false
  end
end

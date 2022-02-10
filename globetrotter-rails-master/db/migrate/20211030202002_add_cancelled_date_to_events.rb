class AddCancelledDateToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :cancelled_date, :timestamp
  end
end

class AddPublishedToTours < ActiveRecord::Migration[6.1]
  def change
    add_column :tours, :published, :boolean, default: false
  end
end

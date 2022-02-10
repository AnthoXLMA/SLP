class AddDeletedAtToAllTables < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :deleted_at, :timestamp
    add_column :guides, :published, :boolean, default: false, default: false, null: false
    add_column :guides, :deleted_at, :timestamp
    add_column :tours, :deleted_at, :timestamp
    add_column :events, :deleted_at, :timestamp
    change_column_null :tours, :published, false
  end
end

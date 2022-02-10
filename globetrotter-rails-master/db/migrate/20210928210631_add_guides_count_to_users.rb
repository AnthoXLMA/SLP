class AddGuidesCountToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :guides_count, :integer, default: 0
    execute <<~SQL
      UPDATE users
      SET guides_count = 1
      FROM guides
      WHERE guides.user_id = users.id
    SQL
  end
end

class RemoveGuideFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :guide, :boolean
  end
end

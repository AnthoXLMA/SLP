class AddMangoPayUserIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :mangopay_user_id, :string
  end
end

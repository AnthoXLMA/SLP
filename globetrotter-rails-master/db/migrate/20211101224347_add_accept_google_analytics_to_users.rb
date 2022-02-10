class AddAcceptGoogleAnalyticsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :accept_google_analytics, :string, limit: 5
  end
end

class AddTourLanguageToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :tour_language, :json
    User.all.each do |u|
      u.language ||= 'en'
      u.tour_language = [u.language]
      u.save!
    end
    change_column :users, :tour_language, :json, null: false
    change_column :users, :language, :string, null: false
  end
end

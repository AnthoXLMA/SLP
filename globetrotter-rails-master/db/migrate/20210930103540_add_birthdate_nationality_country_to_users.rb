class AddBirthdateNationalityCountryToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :birthdate, :date
    add_column :users, :nationality, :string
    add_column :users, :country, :string
  end
end

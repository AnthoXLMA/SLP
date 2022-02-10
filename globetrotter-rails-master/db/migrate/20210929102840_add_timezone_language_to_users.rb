class AddTimezoneLanguageToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :timezone, :string
    add_column :users, :language, :string
  end
end

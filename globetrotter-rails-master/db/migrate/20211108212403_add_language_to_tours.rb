class AddLanguageToTours < ActiveRecord::Migration[6.1]
  def change
    add_column :tours, :language, :string, null: false, default: 'en'
  end
end

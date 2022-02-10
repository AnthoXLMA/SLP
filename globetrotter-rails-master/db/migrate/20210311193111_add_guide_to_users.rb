# frozen_string_literal: true

class AddGuideToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :guide, :boolean, null: false, default: false
  end
end

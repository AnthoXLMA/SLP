# frozen_string_literal: true

class RemoveDescriptionFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :description, :string
  end
end

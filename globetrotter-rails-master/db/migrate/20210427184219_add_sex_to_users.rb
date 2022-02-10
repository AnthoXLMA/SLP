# frozen_string_literal: true

class AddSexToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :sex, 'char(1)'
  end
end

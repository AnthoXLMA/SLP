# frozen_string_literal: true

class ModifyColumnEventDateNotNullable < ActiveRecord::Migration[6.1]
  def change
    execute 'update events set date = now() where date is null'
    change_column_null :events, :date, false
  end
end

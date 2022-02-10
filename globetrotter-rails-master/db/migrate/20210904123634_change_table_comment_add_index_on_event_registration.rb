# frozen_string_literal: true

class ChangeTableCommentAddIndexOnEventRegistration < ActiveRecord::Migration[6.1]
  def change
    execute <<~SQL
      delete from comments
      where event_registration_id in (
        select event_registration_id from comments group by event_registration_id having count(*) > 1
      )
    SQL
    remove_index :comments, :event_registration_id
    add_index :comments, :event_registration_id, unique: true
  end
end

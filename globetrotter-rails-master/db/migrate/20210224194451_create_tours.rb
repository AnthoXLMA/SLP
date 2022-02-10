# frozen_string_literal: true

class CreateTours < ActiveRecord::Migration[6.1]
  def change
    create_table :tours do |t|
      t.string :title
      t.string :subtitle
      t.float :rating
      t.string :description
      t.string :guide
      t.date :next_date
      t.integer :comments_count

      t.timestamps
    end
  end
end

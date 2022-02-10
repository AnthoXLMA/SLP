# frozen_string_literal: true

class RemoveRatingFromTours < ActiveRecord::Migration[6.1]
  def change
    remove_column :tours, :rating, :float
    remove_column :tours, :comments_count, :integer
  end
end

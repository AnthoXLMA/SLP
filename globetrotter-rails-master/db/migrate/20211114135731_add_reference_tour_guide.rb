class AddReferenceTourGuide < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :tours, :guides
  end
end

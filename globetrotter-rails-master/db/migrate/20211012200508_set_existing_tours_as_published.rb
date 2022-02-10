class SetExistingToursAsPublished < ActiveRecord::Migration[6.1]
  def change
    execute <<~SQL
      update tours set published = true
    SQL
  end
end

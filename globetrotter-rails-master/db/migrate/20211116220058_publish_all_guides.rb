class PublishAllGuides < ActiveRecord::Migration[6.1]
  def change
    execute 'UPDATE guides set published = true'
  end
end

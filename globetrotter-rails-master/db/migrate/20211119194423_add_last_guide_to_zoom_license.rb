class AddLastGuideToZoomLicense < ActiveRecord::Migration[6.1]
  def change
    add_reference :zoom_licenses, :last_guide, null: true, foreign_key: { to_table: :guides }
  end
end

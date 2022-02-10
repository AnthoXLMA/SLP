class RenameTableGuideInfoToGuide < ActiveRecord::Migration[6.1]
  def change
    rename_table :guide_infos, :guides
    rename_column :tours, :guide_info_id, :guide_id
    execute <<~SQL
      update active_storage_attachments
      set record_type = 'Guide'
      where record_type = 'GuideInfo'
    SQL
  end
end

class ChangeUserImageToGuideImage < ActiveRecord::Migration[6.1]
  def change
    execute <<~SQL
      update active_storage_attachments
      set record_type = 'GuideInfo', record_id = guide_infos.id
      from guide_infos
      where active_storage_attachments.record_id = guide_infos.user_id
        and active_storage_attachments.record_type = 'User'
        and active_storage_attachments.name = 'image'
    SQL
  end
end

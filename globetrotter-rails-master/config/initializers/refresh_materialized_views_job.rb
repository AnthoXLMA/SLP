Rails.application.reloader.to_prepare do
  if Delayed::Job.where('locked_by is null and handler like ?', '%RefreshMaterializedViewsJob%').count == 0
    RefreshMaterializedViewsJob.perform_later
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
end

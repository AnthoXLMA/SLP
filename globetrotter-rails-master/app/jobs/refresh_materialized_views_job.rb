class RefreshMaterializedViewsJob < ApplicationJob
  queue_as :default

  def perform
    NextEvent.refresh
    RefreshMaterializedViewsJob.set(wait: 5.minutes).perform_later
  end
end

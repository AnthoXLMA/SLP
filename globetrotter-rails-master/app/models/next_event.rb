class NextEvent < Event
  self.table_name = 'next_events'
  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW next_events')
  end
end

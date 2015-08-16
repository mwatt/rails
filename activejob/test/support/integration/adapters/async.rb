module AsyncJobsManager
  def setup
    ActiveJob::Base.queue_adapter = :async
  end
end

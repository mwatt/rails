require 'concurrent'
require 'active_job/async_job'

ActiveJob::Base.queue_adapter = :async
ActiveJob::AsyncJob.set_test_mode!

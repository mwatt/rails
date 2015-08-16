require 'concurrent'

ActiveJob::Base.queue_adapter = :async
ActiveJob::QueueAdapters::AsyncAdapter.executor = Concurrent::ImmediateExecutor.new

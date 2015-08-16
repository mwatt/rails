require 'concurrent'

ActiveJob::Base.queue_adapter = :async
ActiveJob::QueueAdapters::AsyncAdapter.default_executor = Concurrent::ImmediateExecutor.new

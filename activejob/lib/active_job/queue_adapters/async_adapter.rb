require 'concurrent'

module ActiveJob
  module QueueAdapters
    # == Active Job Async adapter
    #
    # When enqueueing jobs with the Async adapter the job will be executed
    # asynchronously on a +concurrent-ruby+ thread pool.
    #
    # Concurrent Ruby: Modern concurrency tools including agents, futures,
    # promises, thread pools, supervisors, and more. Inspired by Erlang,
    # Clojure, Scala, Go, Java, JavaScript, and classic concurrency patterns.
    #
    # Read more about Concurrent Ruby {here}[https://github.com/ruby-concurrency/concurrent-ruby].
    #
    # To use Async set the queue_adapter config to +:async+.
    #
    #   Rails.application.config.active_job.queue_adapter = :async
    class AsyncAdapter
      include ActiveSupport::Configurable

      DEFAULT_MAX_THREADS = 200

      class << self
        def create_default_executor
          Concurrent::ThreadPoolExecutor.new(
            min_threads:     [2, Concurrent.processor_count].max,
            max_threads:     DEFAULT_MAX_THREADS,
            auto_terminate:  true,
            idletime:        60, # 1 minute
            max_queue:       0, # unlimited
            fallback_policy: :caller_runs # shouldn't matter -- 0 max queue
          )
        end
      end

      config_accessor :executor do
        AsyncAdapter.create_default_executor
      end

      def enqueue(job) #:nodoc:
        AsyncAdapter.executor.post { Base.execute(job.serialize) }
      end

      def enqueue_at(job, timestamp) #:nodoc:
        raise NotImplementedError, "This queueing backend does not support scheduling jobs. To see what features are supported go to http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html"
      end
    end
  end
end

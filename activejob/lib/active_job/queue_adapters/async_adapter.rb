require 'concurrent'
require 'thread_safe'

module ActiveJob
  module QueueAdapters
    # == Active Job Async adapter
    #
    # When enqueueing jobs with the Async adapter the job will be executed
    # asynchronously on a +concurrent-ruby+ thread pool. All job data
    # is retained in memory. Because job data is not saved to a persistent
    # datastore there is no additional infrastructure needed and most jobs
    # will process very quickly. The lack of persistence, however, means
    # that all unprocessed jobs will be lost on application restart. This makes
    # in-memory queue adapters unsuitable for most production environments
    # but excellent for development and testing.
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
    #
    # By default, jobs will be executed on the default executor, a thread pool
    # which can grow as needed up to a pre-determined maximum. The default
    # executor can be manually set during application initialization using the
    # +default_executor+ accessor. Any +concurrent-ruby+ thread pool can be
    # used as the default executor:
    #
    #   ActiveJob::QueueAdapters::AsyncAdapter.default_executor = Concurrent::CachedThreadPool.new
    #
    # The async adapter supports job queues specified with +queue_as+. Queues
    # are implemented as individual thread pools. Queues can be created during
    # application initialization using the +create_queue+ method:
    #
    #   ActiveJob::QueueAdapters::AsyncAdapter.create_queue(:my_queue)
    #
    # A queue created this way will be a thread pool with a fixed number of
    # threads (minimum of 2). To explicitly specify the number of threads in
    # the pool use the +workers+ option:
    #
    #   ActiveJob::QueueAdapters::AsyncAdapter.create_queue(:this_queue, workers: 2)
    #
    # Any +concurrent-ruby+ thread pool can be set as a queue's executor. This
    # allows for a high degree of configuration and even allows queues to share
    # a single thread pool. Simply create the thread pool first and pass it as the
    # +executor+ option:
    #
    #   executor = Concurrent::FixedThreadPool.new(10, max_queue: 100, fallback_polcy: :caller_runs)
    #   ActiveJob::QueueAdapters::AsyncAdapter.create_queue(:new_queue_name, executor: executor)
    #
    # When a queue is specified using +queue_as+ but a queue with that name
    # does not exist the job will be run on the default executor.
    class AsyncAdapter
      include ActiveSupport::Configurable

      DEFAULT_MIN_THREADS = [2, Concurrent.processor_count].max
      DEFAULT_MAX_THREADS = Concurrent.processor_count * 100

      DEFAULT_EXECUTOR_OPTIONS = {
        min_threads:     DEFAULT_MIN_THREADS,
        max_threads:     DEFAULT_MAX_THREADS,
        auto_terminate:  true,
        idletime:        60, # 1 minute
        max_queue:       0, # unlimited
        fallback_policy: :caller_runs # shouldn't matter -- 0 max queue
      }.freeze

      QUEUES = ThreadSafe::Cache.new { AsyncAdapter.default_executor } #:nodoc:

      class << self
        def create_queue(name, opts = {})
          raise ArgumentError.new("queue '#{name}' already exists") if QUEUES.key?(name)
          QUEUES[name] = if opts.key?(:executor)
                           opts[:executor]
                         else
                           workers = opts.fetch(:workers, DEFAULT_MIN_THREADS)
                           Concurrent::FixedThreadPool.new(workers, DEFAULT_EXECUTOR_OPTIONS)
                         end
        end
      end

      config_accessor :default_executor do
        Concurrent::ThreadPoolExecutor.new(DEFAULT_EXECUTOR_OPTIONS)
      end

      def enqueue(job) #:nodoc:
        QUEUES[job.queue_name].post { Base.execute(job.serialize) }
      end

      def enqueue_at(job, timestamp) #:nodoc:
        delay = timestamp - Time.current.to_f
        if delay > 0
          Concurrent::ScheduledTask.execute(delay, executor: QUEUES[job.queue_name]) do
            Base.execute(job.serialize)
          end
        else
          enqueue(job)
        end
      end
    end
  end
end

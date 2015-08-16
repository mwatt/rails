require 'concurrent'
require 'thread_safe'

module ActiveJob
  # == Active Job Async Job
  #
  # When enqueueing jobs with Async Job each job will be executed
  # asynchronously on a +concurrent-ruby+ thread pool. All job data
  # is retained in memory. Because job data is not saved to a persistent
  # datastore there is no additional infrastructure needed and most jobs
  # will process very quickly. The lack of persistence, however, means
  # that all unprocessed jobs will be lost on application restart. This
  # makes in-memory queue adapters unsuitable for most production
  # environments but excellent for development and testing.
  #
  # Read more about Concurrent Ruby {here}[https://github.com/ruby-concurrency/concurrent-ruby].
  #
  # To use Async Job set the queue_adapter config to +:async+.
  #
  #   Rails.application.config.active_job.queue_adapter = :async
  #
  # Async Job supports job queues specified with +queue_as+. Queues
  # are implemented as individual thread pools. Queues will be created
  # automatically as needed using a default configuration. Should there be a
  # need to customize the thread pool behind one or more queues, any
  # concurrent-ruby thread pool can be injected. Simply create the thread
  # pool directly then call the +create_queue+ method passing the thread
  # pool as the second parameter:
  #
  #   thread_pool = Concurrent::FixedThreadPool.new(10, max_queue: 100, fallback_polcy: :caller_runs)
  #   ActiveJob::AsyncJob.create_queue(:my_queue, thread_pool)
  #
  # The +create_queue+ method must be called during application initialization,
  # before any jobs are post to the queue. Attempting to create a queue that
  # already exists will raise an error.
  class AsyncJob

    DEFAULT_EXECUTOR_OPTIONS = {
      min_threads:     [2, Concurrent.processor_count].max,
      max_threads:     Concurrent.processor_count * 10,
      auto_terminate:  true,
      idletime:        60, # 1 minute
      max_queue:       0, # unlimited
      fallback_policy: :caller_runs # shouldn't matter -- 0 max queue
    }.freeze

    QUEUES = ThreadSafe::Cache.new do |hash, queue_name| #:nodoc:
      hash[queue_name] = ActiveJob::AsyncJob.create_thread_pool
    end

    # Raised when an attempt is made to create a queue that already exists.
    class QueueCreationError < ArgumentError; end

    class << self
      # Force all jobs to run synchronously when testing the Active Job gem.
      def set_test_mode! #:nodoc:
        @test_mode = true
      end

      # Create a new job queue with the given +name+. Jobs will run on the
      # given +thread pool+. The thread pool must be a concurrent-ruby
      # {executor}[http://ruby-concurrency.github.io/concurrent-ruby/file.thread_pools.html].
      # Raises +QueueCreationError+ when the queue already exists.
      def create_queue(name, thread_pool)
        raise QueueCreationError.new('queue already exists') if QUEUES.key? name
        # possible race condition here but the use case is very narrow
        QUEUES[name] = thread_pool
      end

      def create_thread_pool #:nodoc:
        if @test_mode
          Concurrent::ImmediateExecutor.new
        else
          Concurrent::ThreadPoolExecutor.new(DEFAULT_EXECUTOR_OPTIONS)
        end
      end

      def enqueue(job) #:nodoc:
        QUEUES[job.queue_name].post { ActiveJob::Base.execute(job.serialize) }
      end

      def enqueue_at(job, timestamp) #:nodoc:
        delay = timestamp - Time.current.to_f
        if delay > 0
          Concurrent::ScheduledTask.execute(delay, executor: QUEUES[job.queue_name]) do
            ActiveJob::Base.execute(job.serialize)
          end
        else
          enqueue(job)
        end
      end
    end
  end
end

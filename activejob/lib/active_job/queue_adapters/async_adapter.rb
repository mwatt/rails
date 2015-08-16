require 'active_job/async_job'

module ActiveJob
  module QueueAdapters
    # == Async adapter for Active Job
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
    # Concurrent Ruby: Modern concurrency tools including agents, futures,
    # promises, thread pools, supervisors, and more. Inspired by Erlang,
    # Clojure, Scala, Go, Java, JavaScript, and classic concurrency patterns.
    #
    # Read more about Async Job {here}[http://api.rubyonrails.org/classes/ActiveJob/AsyncJob.html]
    #
    # Read more about Concurrent Ruby {here}[https://github.com/ruby-concurrency/concurrent-ruby].
    #
    # To use Async Job set the queue_adapter config to +:async+.
    #
    #   Rails.application.config.active_job.queue_adapter = :async
    class AsyncAdapter

      def enqueue(job) #:nodoc:
        ActiveJob::AsyncJob.enqueue(job.serialize, queue: job.queue_name)
      end

      def enqueue_at(job, timestamp) #:nodoc:
        ActiveJob::AsyncJob.enqueue_at(job.serialize, timestamp, queue: job.queue_name)
      end
    end
  end
end

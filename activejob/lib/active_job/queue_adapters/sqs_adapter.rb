require 'shoryuken'

module ActiveJob
  module QueueAdapters
    # == Amazon Simple Queue Service adapter for Active Job
    #
    # Super-efficient AWS SQS thread-based message processor. for Ruby.
    #
    # Read more about SQS {here}[https://aws.amazon.com/sqs/].
    #
    # To use SQS set the queue_adapter config to +:sqs+.
    #
    #   Rails.application.config.active_job.queue_adapter = :sqs
    class SqsAdapter
      def enqueue(job) #:nodoc:
        fail NotImplementedError
       end

      def enqueue_at(job, timestamp) #:nodoc:
        fail NotImplementedError
      end

      class JobWrapper #:nodoc:
        include Shoryuken::Worker

        shoryuken_options queue: 'default'

        def perform(sqs_msg, body)
          Base.execute body
        end
      end
    end
  end
end
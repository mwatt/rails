module ActiveJob
  module MaxRetry
    extend ActiveSupport::Concern

    # Includes the ability to override the default max_attempts.
    module ClassMethods

      mattr_accessor(:default_max_retry) { nil }

      # Specifies the max attempts for the job.
      #
      #   class PublishToFeedJob < ActiveJob::Base
      #     max_retry 2
      #
      #     def perform(post)
      #       post.to_feed!
      #     end
      #   end
      def max_retry(max_retries=nil, &block)
        if block_given?
          self.max_attempts = block
        else
          self.max_attempts = max_attempts_from_part(max_retries)
        end
      end

      def max_attempts_from_part(max_retries) #:nodoc:
        ("#{max_retries}".to_i > 0 ? "#{max_retries}".to_i : default_max_retry )
      end

    end

    included do
      class_attribute :max_attempts, instance_accessor: false

      self.max_attempts = default_max_retry
    end

    # Returns the max attempts of current job
    def max_attempts
      if @max_attempts.is_a?(Proc)
        @max_attempts = self.class.max_attempts_from_part(instance_exec(&@max_attempts))
      end
      @max_attempts
    end

  end
end

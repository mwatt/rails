module ActiveRecord
  module ConnectionAdapters
    module AbstractMysqlAdapter
      module Quoting
        # Quote date/time values for use in SQL input.
        def quoted_date(value) #:nodoc:
          if @connection.supports_datetime_with_precision?
            super
          else
            super.sub(/\.\d{6}\z/, '')
          end
        end
      end
    end
  end
end

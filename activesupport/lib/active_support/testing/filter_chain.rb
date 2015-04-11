module ActiveSupport
  module Testing
    class FilterChain # :nodoc:
      def initialize(runnable, filter, patterns)
        @runnable = runnable
        @filters = [ derive_regexp(filter), *derive_filters(patterns) ].compact
      end

      def any?
        @filters.any?
      end

      def ===(method)
        @filters.any? { |filter| filter === method }
      end

      private
        def derive_regexp(filter)
          filter =~ %r%/(.*)/% ? Regexp.new($1) : filter
        end

        def derive_filters(patterns)
          Array(patterns).map do |file_and_line|
            file, line = file_and_line.split(":")
            Filter.new(@runnable, File.expand_path(file), line.to_i) if file && line
          end
        end

        class Filter # :nodoc:
          def initialize(runnable, file, line)
            @runnable, @file, @line = runnable, file, line
          end

          def ===(method)
            if @runnable.method_defined?(method)
              test_file, test_range = definition_for(@runnable.instance_method(method))
              test_file == @file && test_range.include?(@line)
            end
          end

          private
            def definition_for(method)
              file, start_line = method.source_location
              end_line = method.source.count("\n") + start_line - 1

              return file, start_line..end_line
            end
        end
    end
  end
end

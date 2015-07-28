require 'action_dispatch/http/parameter_filter'

module ActionDispatch
  module Http
    module FilterRedirect

      FILTERED = '[FILTERED]'.freeze # :nodoc:

      def filtered_location # :nodoc:
        if location_filter_match?
          FILTERED
        else
          parameter_filtered_location
        end
      end

    private

      def location_filters
        if request
          request.get_header('action_dispatch.redirect_filter') || []
        else
          []
        end
      end

      def location_filter_match?
        location_filters.any? do |filter|
          if String === filter
            location.include?(filter)
          elsif Regexp === filter
            location =~ filter
          end
        end
      end

      DEFAULT_PARAMETER_FILTER = []
      def parameter_filter
        ParameterFilter.new request.fetch_header('action_dispatch.parameter_filter') {
          DEFAULT_PARAMETER_FILTER
        }
      end

      KV_RE   = '[^&;=]+'
      PAIR_RE = %r{(#{KV_RE})=(#{KV_RE})}
      def parameter_filtered_location
        uri = URI.parse(location)
        unless uri.query.nil? || uri.query.empty?
          uri.query.gsub!(PAIR_RE) do |_|
            parameter_filter.filter([[$1, $2]]).first.join('=')
          end
        end
        uri.to_s
      end
    end
  end
end

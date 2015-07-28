module ActionDispatch
  module Http
    module FilterRedirect

      FILTERED = '[FILTERED]'.freeze # :nodoc:

      def filtered_location # :nodoc:
        filters = location_filter
        if !filters.empty? && location_filter_match?(filters)
          FILTERED
        else
          parameter_filtered_location
        end
      end

    private

      def location_filter
        if request
          request.env['action_dispatch.redirect_filter'] || []
        else
          []
        end
      end

      def location_filter_match?(filters)
        filters.any? do |filter|
          if String === filter
            location.include?(filter)
          elsif Regexp === filter
            location.match(filter)
          end
        end
      end

      DEFAULT_PARAMETER_FILTER = [/.*/]
      def parameter_filter
        ParameterFilter.new request.env.fetch('action_dispatch.parameter_filter') {
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

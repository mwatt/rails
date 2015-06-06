require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/object/acts_like'

module ActiveSupport
  # Provides accurate date and time measurements using Date#advance and
  # Time#advance, respectively. It mainly supports the methods on Numeric.
  #
  #   1.month.ago       # equivalent to Time.now.advance(months: -1)
  class Duration
    attr_accessor :value, :parts

    def initialize(value, parts) #:nodoc:
      @value, @parts = value, parts
    end

    # Adds another Duration or a Numeric to this Duration. Numeric values
    # are treated as seconds.
    def +(other)
      if Duration === other
        Duration.new(value + other.value, @parts + other.parts)
      else
        Duration.new(value + other, @parts + [[:seconds, other]])
      end
    end

    # Subtracts another Duration or a Numeric from this Duration. Numeric
    # values are treated as seconds.
    def -(other)
      self + (-other)
    end

    def -@ #:nodoc:
      Duration.new(-value, parts.map { |type,number| [type, -number] })
    end

    def is_a?(klass) #:nodoc:
      Duration == klass || value.is_a?(klass)
    end
    alias :kind_of? :is_a?

    def instance_of?(klass) # :nodoc:
      Duration == klass || value.instance_of?(klass)
    end

    # Returns +true+ if +other+ is also a Duration instance with the
    # same +value+, or if <tt>other == value</tt>.
    def ==(other)
      if Duration === other
        other.value == value
      else
        other == value
      end
    end

    # Returns the amount of seconds a duration covers as a string.
    # For more information check to_i method.
    #
    #   1.day.to_s # => "86400"
    def to_s
      @value.to_s
    end

    # Returns the number of seconds that this Duration represents.
    #
    #   1.minute.to_i   # => 60
    #   1.hour.to_i     # => 3600
    #   1.day.to_i      # => 86400
    #
    # Note that this conversion makes some assumptions about the
    # duration of some periods, e.g. months are always 30 days
    # and years are 365.25 days:
    #
    #   # equivalent to 30.days.to_i
    #   1.month.to_i    # => 2592000
    #
    #   # equivalent to 365.25.days.to_i
    #   1.year.to_i     # => 31557600
    #
    # In such cases, Ruby's core
    # Date[http://ruby-doc.org/stdlib/libdoc/date/rdoc/Date.html] and
    # Time[http://ruby-doc.org/stdlib/libdoc/time/rdoc/Time.html] should be used for precision
    # date and time arithmetic.
    def to_i
      @value.to_i
    end

    # Returns +true+ if +other+ is also a Duration instance, which has the
    # same parts as this one.
    def eql?(other)
      Duration === other && other.value.eql?(value)
    end

    def hash
      @value.hash
    end

    def self.===(other) #:nodoc:
      other.is_a?(Duration)
    rescue ::NoMethodError
      false
    end

    # Calculates a new Time or Date that is as far in the future
    # as this Duration represents.
    def since(time = ::Time.current)
      sum(1, time)
    end
    alias :from_now :since

    # Calculates a new Time or Date that is as far in the past
    # as this Duration represents.
    def ago(time = ::Time.current)
      sum(-1, time)
    end
    alias :until :ago

    # Creates a new Time or Date range
    # that starts at +time+
    # and lasts for the duration specified in the method receiver
    #
    #   1.month.range_from(3.months.ago) # equivalent to 3.months.ago..2.months.ago
    #   1.month.range_from_now # equivalent to Time.current..1.month.from_now
    def range_from(time = ::Time.current)
      time..since(time)
    end
    alias :range_from_now :range_from

    # Creates a new Time or Date range
    # lasting for the duration specified in the method receiver
    # and ending at +time+.
    #
    #   3.months.range_until(1.month.ago) # equivalent to 4.months.ago..1.month.ago
    #   1.month.range_until_now # equivalent to 1.month.ago..Time.current
    def range_until(time = ::Time.current)
      ago(time)..time
    end
    alias :range_until_now :range_until

    def inspect #:nodoc:
      parts.
        reduce(::Hash.new(0)) { |h,(l,r)| h[l] += r; h }.
        sort_by {|unit,  _ | [:years, :months, :days, :minutes, :seconds].index(unit)}.
        map     {|unit, val| "#{val} #{val == 1 ? unit.to_s.chop : unit.to_s}"}.
        to_sentence(locale: ::I18n.default_locale)
    end

    def as_json(options = nil) #:nodoc:
      to_i
    end

    def respond_to_missing?(method, include_private=false) #:nodoc:
      @value.respond_to?(method, include_private)
    end

    delegate :<=>, to: :value

    protected

      def sum(sign, time = ::Time.current) #:nodoc:
        parts.inject(time) do |t,(type,number)|
          if t.acts_like?(:time) || t.acts_like?(:date)
            if type == :seconds
              t.since(sign * number)
            else
              t.advance(type => sign * number)
            end
          else
            raise ::ArgumentError, "expected a time or date, got #{time.inspect}"
          end
        end
      end

    private

      def method_missing(method, *args, &block) #:nodoc:
        value.send(method, *args, &block)
      end
  end
end

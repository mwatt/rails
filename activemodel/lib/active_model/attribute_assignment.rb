require 'active_support/core_ext/hash/keys'

module ActiveModel
  module AttributeAssignment
    extend ActiveSupport::Concern

    include ActiveModel::ForbiddenAttributesProtection

    # Alias for `assign_attributes`.
    def attributes=(attributes)
      assign_attributes(attributes)
    end

    # Allows you to set all the attributes by passing in a hash of attributes with
    # keys matching the attribute names.
    #
    # If the passed hash responds to <tt>permitted?</tt> method and the return value
    # of this method is +false+ an <tt>ActiveModel::ForbiddenAttributesError</tt>
    # exception is raised.
    #
    #   class Cat
    #     include ActiveModel::AttributeAssignment
    #     attr_accessor :name, :status
    #   end
    #
    #   cat = Cat.new
    #   cat.assign_attributes(name: "Gorby", status: "yawning")
    #   cat.name # => 'Gorby'
    #   cat.status => 'yawning'
    #   cat.assign_attributes(status: "sleeping")
    #   cat.name # => 'Gorby'
    #   cat.status => 'sleeping'
    def assign_attributes(new_attributes)
      if !new_attributes.respond_to?(:stringify_keys)
        raise ArgumentError, "When assigning attributes, you must pass a hash as an argument."
      end
      return if new_attributes.blank?

      attributes = new_attributes.stringify_keys

      multi_parameter_attributes = {}

      attributes.each do |k, v|
        if k.include?("(")
          multi_parameter_attributes[k] = attributes.delete(k)
        end
      end
      _assign_attributes(sanitize_for_mass_assignment(attributes))

      assign_multiparameter_attributes(multi_parameter_attributes) unless multi_parameter_attributes.empty?
    end

    module ClassMethods
      mattr_accessor :typecasted

      def typecast_attribute(attribute, klass)
        self.typecasted ||= {}
        typecasted[attribute] = klass
      end
    end

    private

    # Instantiates objects for all attribute classes that needs more than one constructor parameter. This is done
    # by calling new on the column type or aggregation type (through composed_of) object with these parameters.
    # So having the pairs written_on(1) = "2004", written_on(2) = "6", written_on(3) = "24", will instantiate
    # written_on (a date type) with Date.new("2004", "6", "24"). You can also specify a typecast character in the
    # parentheses to have the parameters typecasted before they're used in the constructor. Use i for Fixnum and
    # f for Float. If all the values for a given attribute are empty, the attribute will be set to +nil+.
    def assign_multiparameter_attributes(pairs)
      execute_callstack_for_multiparameter_attributes(
        extract_callstack_for_multiparameter_attributes(pairs)
      )
    end

    def execute_callstack_for_multiparameter_attributes(callstack)
      errors = []
      callstack.each do |name, values_with_empty_parameters|
        begin
          if values_with_empty_parameters.each_value.all?(&:nil?)
            values = nil
          else
            values = values_with_empty_parameters
          end
          _assign_attribute(name, values)
        rescue => ex
          errors << attribute_assignment_error_klass.new("error on assignment #{values_with_empty_parameters.values.inspect} to #{name} (#{ex.message})", ex, name)
        end
      end
      unless errors.empty?
        error_descriptions = errors.map(&:message).join(",")
        raise multiparameter_assignment_errors_klass.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes [#{error_descriptions}]"
      end
    end

    def extract_callstack_for_multiparameter_attributes(pairs)
      attributes = {}

      pairs.each do |(multiparameter_name, value)|
        attribute_name = multiparameter_name.split("(").first
        attributes[attribute_name] ||= {}

        parameter_value = value.empty? ? nil : type_cast_attribute_value(multiparameter_name, value)
        attributes[attribute_name][find_parameter_position(multiparameter_name)] ||= parameter_value
      end

      attributes
    end

    def type_cast_attribute_value(multiparameter_name, value)
      multiparameter_name =~ /\([0-9]*([if])\)/ ? value.send("to_" + $1) : value
    end

    def find_parameter_position(multiparameter_name)
      multiparameter_name.scan(/\(([0-9]*).*\)/).first.first.to_i
    end

    def attribute_assignment_error_klass
      ActiveModel::AttributeAssignmentError
    end

    def multiparameter_assignment_errors_klass
      ActiveModel::MultiparameterAssignmentErrors
    end

    def _assign_attributes(attributes)
      attributes.each do |k, v|
        _assign_attribute(k, v)
      end
    end

    def _assign_attribute(k, v)
      if respond_to?("#{k}=")
        if v.present? && self.class.typecasted.key?(k.to_sym) && v.class != self.class.typecasted[k.to_sym]
          v = Typecaster.new(v, self.class.typecasted[k.to_sym]).typecast
        end

        public_send("#{k}=", v)
      else
        raise UnknownAttributeError.new(self, k)
      end
    end
  end

  class Typecaster
    def initialize(values, klass)
      @values = values
      @klass = klass
    end

    def typecast
      return if @values.values.compact.empty?

      if @klass == Time
        read_time
      elsif @klass == Date
        read_date
      else
        read_other
      end
    end

    private

    def instantiate_time_object(set_values)
      Time.zone.local(*set_values)
    end

    def read_time
      validate_required_parameters!([1,2,3])
      return if blank_date_parameter?

      max_position = extract_max_param(6)
      set_values   = @values.values_at(*(1..max_position))
      # If Time bits are not there, then default to 0
      (3..5).each { |i| set_values[i] = set_values[i].presence || 0 }
      instantiate_time_object(set_values)
    end

    def read_date
      return if blank_date_parameter?
      set_values = @values.values_at(1,2,3)
      begin
        Date.new(*set_values)
      rescue ArgumentError # if Date.new raises an exception on an invalid date instantiate_time_object(set_values).to_date # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
      end
    end

    def read_other
      max_position = extract_max_param
      positions    = (1..max_position)
      validate_required_parameters!(positions)

      set_values = @values.values_at(*positions)
      @klass.new(*set_values)
    end

    # Checks whether some blank date parameter exists. Note that this is different
    # than the validate_required_parameters! method, since it just checks for blank
    # positions instead of missing ones, and does not raise in case one blank position
    # exists. The caller is responsible to handle the case of this returning true.
    def blank_date_parameter?
      (1..3).any? { |position| @values[position].blank? }
    end

    # If some position is not provided, it errors out a missing parameter exception.
    def validate_required_parameters!(positions)
      if missing_parameter = positions.detect { |position| !@values.key?(position) }
        raise ArgumentError.new("Missing Parameter - #{name}(#{missing_parameter})")
      end
    end

    def extract_max_param(upper_cap = 100)
      [@values.keys.max, upper_cap].min
    end
  end

  # Raised when an error occurred while doing a mass assignment to an attribute through the
  # +attributes=+ method. The exception has an +attribute+ property that is the name of the
  # offending attribute.
  class AttributeAssignmentError < StandardError
    attr_reader :exception, :attribute

    def initialize(message, exception, attribute)
      super(message)
      @exception = exception
      @attribute = attribute
    end
  end

  # Raised when there are multiple errors while doing a mass assignment through the +attributes+
  # method. The exception has an +errors+ property that contains an array of AttributeAssignmentError
  # objects, each corresponding to the error while assigning to an attribute.
  class MultiparameterAssignmentErrors < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end
  end
end

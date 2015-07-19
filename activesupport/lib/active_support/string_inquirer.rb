module ActiveSupport
  # Wrapping a string in this class gives you a prettier way to test
  # for equality. The value returned by <tt>Rails.env</tt> is wrapped
  # in a StringInquirer object, so instead of calling this:
  #
  #   Rails.env == 'production'
  #
  # you can call this:
  #
  #   Rails.env.production?
  class StringInquirer < String

    def initialize(value, valid_values = [])
      super(value)

      if valid_values.any?
        extend RestrictStringInquirer
        define_inquiry_methods(valid_values)
      else
        extend DynamicStringInquirer
      end
    end
  end

  module RestrictStringInquirer
    private

      def define_inquiry_methods(valid_values)
        class_eval do
          define_method(:valid_values) { valid_values }

          valid_values.each do |value|
            define_method("#{value}?") { self == value }
          end
        end
      end
  end

  module DynamicStringInquirer
    private

      def respond_to_missing?(method_name, include_private = false)
        method_name[-1] == '?'
      end

      def method_missing(method_name, *arguments)
        if method_name[-1] == '?'
          self == method_name[0..-2]
        else
          super
        end
      end
  end
end

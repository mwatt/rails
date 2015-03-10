module ActiveSupport
  # Wrapping an array in an +ArrayInquirer+ gives a friendlier way to check
  # its string-like contents. For example, <tt>request.variant</tt> returns an
  # +ArrayInquirer+ object. To check a request's variants, you can call:
  #
  #   request.variant.phone?
  #   request.variant.any?(:phone, :tablet)
  #
  # ...instead of:
  #
  #   request.variant.include?(:phone)
  #   request.variant.any? { |v| v.in?([:phone, :tablet]) }
  class ArrayInquirer < Array
    def any?(*candidates, &block)
      if candidates.none?
        super
      else
        (self & candidates).any?
      end
    end

    private
      def respond_to_missing?(name, include_private = false)
        name[-1] == '?'
      end

      def method_missing(name, *args)
        if name[-1] == '?'
          any?(name[0..-2]) || any?(name[0..-2].to_sym)
        else
          super
        end
      end
  end
end

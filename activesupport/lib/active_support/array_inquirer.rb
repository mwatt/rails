module ActiveSupport
  # Wrapping an array in an +ArrayInquirer+ gives a friendlier way to check
  # its string-like contents:
  #
  #   variants = ActiveSupport::ArrayInquirer.new([:phone, :tablet])
  #
  #   variants.phone?    # => true
  #   variants.tablet?   # => true
  #   variants.desktop?  # => false
  #
  #   variants.any?(:phone, :tablet)   # => true
  #   variants.any?(:phone, :desktop)  # => true
  #   variants.any?(:desktop, :watch)  # => false
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

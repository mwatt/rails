module ActiveRecord
  # = Active Record Touch Later
  module TouchLater
    extend ActiveSupport::Concern

    included do
      before_commit_without_transaction_enrollment :touch_deferred_attributes
    end

    def touch_later(*names) # :nodoc:
      raise ActiveRecordError, "cannot touch on a new record object" unless persisted?

      @_defer_touch_attrs ||= timestamp_attributes_for_update_in_model
      @_defer_touch_attrs |= names
      @_touch_time = current_time_from_proper_timezone

      surreptitiously_touch @_defer_touch_attrs
      self.class.connection.add_transaction_record self
    end

    def touch(*names, time: nil) # :nodoc:
      if has_defer_touch_attrs?
        names = names.concat @_defer_touch_attrs
      end
      super(*(names.uniq), time: time)
    end

    private
      def surreptitiously_touch(attrs)
        attrs.each { |attr| write_attribute attr, @_touch_time }
        clear_attribute_changes attrs
      end

      def touch_deferred_attributes
        if has_defer_touch_attrs? && persisted?
          @_disable_touch_later = true
          touch(*@_defer_touch_attrs, time: @_touch_time)
          @_disable_touch_later, @_defer_touch_attrs, @_touch_time = nil, nil, nil
        end
      end

      def has_defer_touch_attrs?
        defined?(@_defer_touch_attrs) && @_defer_touch_attrs.present?
      end

      def should_touch_association_later?
        !(defined?(@_disable_touch_later) && @_disable_touch_later)
      end
  end
end

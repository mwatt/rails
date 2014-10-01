module ActiveRecord #:nodoc:
  # = Active Record Serialization
  module Serialization
    extend ActiveSupport::Concern
    include ActiveModel::Serializers::JSON

    included do
      self.include_root_in_json = false
    end

    def serializable_hash(options = nil, serialization_method = nil)
      options = options.try(:clone) || {}

      options[:except] = Array(options[:except]).map(&:to_s)
      options[:except] |= Array(self.class.inheritance_column)

      super(options, serialization_method)
    end
  end
end

require 'active_record/serializers/xml_serializer'

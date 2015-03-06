module ActiveRecord
  module Type
    class TypedStore < DelegateClass(Type::Value) # :nodoc:
      # Creates +TypedStore+ type instance and specifies type caster
      # for key.
      def self.create_from_type(basetype, key, type, **options)
        typed_store = new(basetype)
        typed_store.type_for_key(key, type, **options)
        typed_store
      end

      def initialize(subtype)
        @accessor_types = {}
        @store_accessor = subtype.accessor
        super(subtype)
      end

      def type_for_key(key, type, **options)
        if type.is_a?(Symbol)
          type = ActiveRecord::Type.lookup(type, options)
        end
        @accessor_types[key.to_s] = type
      end

      def deserialize(value)
        hash = super
        cast(hash)
      end

      def serialize(value)
        if value
          accessor_types.each do |key, type|
            vkey = value.key?(key) ? key : key.to_sym
            value[vkey] = type.serialize(value[vkey]) if value.key?(vkey)
          end
        end
        super(value)
      end

      def cast(value)
        hash = super
        if hash
          accessor_types.each do |key, type|
            hash[key] = type.cast(hash[key]) if hash.key?(key)
          end
        end
        hash
      end

      def accessor
        self
      end

      def write(object, attribute, key, value)
        if accessor_types.key?(key.to_s)
          value = accessor_types[key.to_s].cast(value)
        end
        store_accessor.write(object, attribute, key, value)
      end

      delegate :read, :prepare, to: :store_accessor

      protected

      attr_reader :accessor_types, :store_accessor
    end
  end
end

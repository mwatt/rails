require 'thread'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/duplicable'
require 'active_support/core_ext/string/filters'

module ActiveRecord
  module Core
    extend ActiveSupport::Concern

    included do
      ##
      # :singleton-method:
      #
      # Accepts a logger conforming to the interface of Log4r which is then
      # passed on to any new database connections made and which can be
      # retrieved on both a class and instance level by calling +logger+.
      mattr_accessor :logger, instance_writer: false

      ##
      # Contains the database configuration - as is typically stored in config/database.yml -
      # as a Hash.
      #
      # For example, the following database.yml...
      #
      #   development:
      #     adapter: sqlite3
      #     database: db/development.sqlite3
      #
      #   production:
      #     adapter: sqlite3
      #     database: db/production.sqlite3
      #
      # ...would result in ActiveRecord::Base.configurations to look like this:
      #
      #   {
      #      'development' => {
      #         'adapter'  => 'sqlite3',
      #         'database' => 'db/development.sqlite3'
      #      },
      #      'production' => {
      #         'adapter'  => 'sqlite3',
      #         'database' => 'db/production.sqlite3'
      #      }
      #   }
      def self.configurations=(config)
        @@configurations = ActiveRecord::ConnectionHandling::MergeAndResolveDefaultUrlConfig.new(config).resolve
      end
      self.configurations = {}

      # Returns fully resolved configurations hash
      def self.configurations
        @@configurations
      end

      ##
      # :singleton-method:
      # Determines whether to use Time.utc (using :utc) or Time.local (using :local) when pulling
      # dates and times from the database. This is set to :utc by default.
      mattr_accessor :default_timezone, instance_writer: false
      self.default_timezone = :utc

      ##
      # :singleton-method:
      # Specifies the format to use when dumping the database schema with Rails'
      # Rakefile. If :sql, the schema is dumped as (potentially database-
      # specific) SQL statements. If :ruby, the schema is dumped as an
      # ActiveRecord::Schema file which can be loaded into any database that
      # supports migrations. Use :ruby if you want to have different database
      # adapters for, e.g., your development and test environments.
      mattr_accessor :schema_format, instance_writer: false
      self.schema_format = :ruby

      ##
      # :singleton-method:
      # Specify whether or not to use timestamps for migration versions
      mattr_accessor :timestamped_migrations, instance_writer: false
      self.timestamped_migrations = true

      ##
      # :singleton-method:
      # Specify whether schema dump should happen at the end of the
      # db:migrate rake task. This is true by default, which is useful for the
      # development environment. This should ideally be false in the production
      # environment where dumping schema is rarely needed.
      mattr_accessor :dump_schema_after_migration, instance_writer: false
      self.dump_schema_after_migration = true

      ##
      # :singleton-method:
      # Specifies which database schemas to dump when calling db:structure:dump.
      # If :schema_search_path (the default), it will dumps any schemas listed in schema_search_path.
      # Use :all to always dumps all schemas regardless of the schema_search_path.
      # A string of comma separated schemas can also be used to pass a custom list of schemas.
      mattr_accessor :dump_schemas, instance_writer: false
      self.dump_schemas = :schema_search_path

      mattr_accessor :maintain_test_schema, instance_accessor: false

      mattr_accessor :belongs_to_required_by_default, instance_accessor: false

      class_attribute :default_connection_handler, instance_writer: false

      def self.connection_handler
        ActiveRecord::RuntimeRegistry.connection_handler || default_connection_handler
      end

      def self.connection_handler=(handler)
        ActiveRecord::RuntimeRegistry.connection_handler = handler
      end

      self.default_connection_handler = ConnectionAdapters::ConnectionHandler.new
    end

    module ClassMethods
      def allocate
        define_attribute_methods
        super
      end

      def initialize_find_by_cache # :nodoc:
        @find_by_statement_cache = {}.extend(Mutex_m)
      end

      def inherited(child_class) # :nodoc:
        # initialize cache at class definition for thread safety
        child_class.initialize_find_by_cache
        super
      end

      def find(*ids) # :nodoc:
        # We don't have cache keys for this stuff yet
        return super unless ids.length == 1
        return super if block_given? ||
                        primary_key.nil? ||
                        scope_attributes? ||
                        columns_hash.include?(inheritance_column) ||
                        ids.first.kind_of?(Array)

        id  = ids.first
        if ActiveRecord::Base === id
          id = id.id
          ActiveSupport::Deprecation.warn(<<-MSG.squish)
            You are passing an instance of ActiveRecord::Base to `find`.
            Please pass the id of the object by calling `.id`
          MSG
        end

        key = primary_key

        statement = cached_find_by_statement(key) { |params|
          where(key => params.bind).limit(1)
        }
        record = statement.execute([id], self, connection).first
        unless record
          raise RecordNotFound, "Couldn't find #{name} with '#{primary_key}'=#{id}"
        end
        record
      rescue RangeError
        raise RecordNotFound, "Couldn't find #{name} with an out of range value for '#{primary_key}'"
      end

      def find_by(*args) # :nodoc:
        return super if scope_attributes? || !(Hash === args.first) || reflect_on_all_aggregations.any?

        hash = args.first

        return super if hash.values.any? { |v|
          v.nil? || Array === v || Hash === v
        }

        # We can't cache Post.find_by(author: david) ...yet
        return super unless hash.keys.all? { |k| columns_hash.has_key?(k.to_s) }

        keys = hash.keys

        statement = cached_find_by_statement(keys) { |params|
          wheres = keys.each_with_object({}) { |param, o|
            o[param] = params.bind
          }
          where(wheres).limit(1)
        }
        begin
          statement.execute(hash.values, self, connection).first
        rescue TypeError => e
          raise ActiveRecord::StatementInvalid.new(e.message, e)
        rescue RangeError
          nil
        end
      end

      def find_by!(*args) # :nodoc:
        find_by(*args) or raise RecordNotFound.new("Couldn't find #{name}")
      end

      def initialize_generated_modules # :nodoc:
        generated_association_methods
      end

      def generated_association_methods
        @generated_association_methods ||= begin
          mod = const_set(:GeneratedAssociationMethods, Module.new)
          include mod
          mod
        end
      end

      # Returns a string like 'Post(id:integer, title:string, body:text)'
      def inspect
        if self == Base
          super
        elsif abstract_class?
          "#{super}(abstract)"
        elsif !connected?
          "#{super} (call '#{super}.connection' to establish a connection)"
        elsif table_exists?
          attr_list = attribute_types.map { |name, type| "#{name}: #{type.type}" } * ', '
          "#{super}(#{attr_list})"
        else
          "#{super}(Table doesn't exist)"
        end
      end

      # Overwrite the default class equality method to provide support for association proxies.
      def ===(object)
        object.is_a?(self)
      end

      # Returns an instance of <tt>Arel::Table</tt> loaded with the current table name.
      #
      #   class Post < ActiveRecord::Base
      #     scope :published_and_commented, -> { published.and(self.arel_table[:comments_count].gt(0)) }
      #   end
      def arel_table # :nodoc:
        @arel_table ||= Arel::Table.new(table_name, type_caster: type_caster)
      end

      # Returns the Arel engine.
      def arel_engine # :nodoc:
        @arel_engine ||=
          if Base == self || connection_handler.retrieve_connection_pool(self)
            self
          else
            superclass.arel_engine
          end
      end

      def predicate_builder # :nodoc:
        @predicate_builder ||= PredicateBuilder.new(table_metadata)
      end

      def type_caster # :nodoc:
        TypeCaster::Map.new(self)
      end

      private

      def cached_find_by_statement(key, &block) # :nodoc:
        @find_by_statement_cache[key] || @find_by_statement_cache.synchronize {
          @find_by_statement_cache[key] ||= StatementCache.create(connection, &block)
        }
      end

      def relation # :nodoc:
        relation = Relation.create(self, arel_table, predicate_builder)

        if finder_needs_type_condition?
          relation.where(type_condition).create_with(inheritance_column.to_sym => sti_name)
        else
          relation
        end
      end

      def table_metadata # :nodoc:
        TableMetadata.new(self, arel_table)
      end
    end

    # New objects can be instantiated as either empty (pass no construction parameter) or pre-set with
    # attributes but not yet saved (pass a hash with key names matching the associated table column names).
    # In both instances, valid attribute keys are determined by the column names of the associated table --
    # hence you can't have attributes that aren't part of the table columns.
    #
    # ==== Example:
    #   # Instantiates a single new object
    #   User.new(first_name: 'Jamie')
    def initialize(attributes = nil)
      @attributes = self.class._default_attributes.dup
      self.class.define_attribute_methods

      init_internals
      initialize_internals_callback

      assign_attributes(attributes) if attributes

      yield self if block_given?
      run_callbacks :initialize
    end

    # Initialize an empty model object from +coder+. +coder+ must contain
    # the attributes necessary for initializing an empty model object. For
    # example:
    #
    #   class Post < ActiveRecord::Base
    #   end
    #
    #   post = Post.allocate
    #   post.init_with('attributes' => { 'title' => 'hello world' })
    #   post.title # => 'hello world'
    def init_with(coder)
      coder = LegacyYamlAdapter.convert(self.class, coder)
      @attributes = coder['attributes']

      init_internals

      @new_record = coder['new_record']

      self.class.define_attribute_methods

      run_callbacks :find
      run_callbacks :initialize

      self
    end

    ##
    # :method: clone
    # Identical to Ruby's clone method.  This is a "shallow" copy.  Be warned that your attributes are not copied.
    # That means that modifying attributes of the clone will modify the original, since they will both point to the
    # same attributes hash. If you need a copy of your attributes hash, please use the #dup method.
    #
    #   user = User.first
    #   new_user = user.clone
    #   user.name               # => "Bob"
    #   new_user.name = "Joe"
    #   user.name               # => "Joe"
    #
    #   user.object_id == new_user.object_id            # => false
    #   user.name.object_id == new_user.name.object_id  # => true
    #
    #   user.name.object_id == user.dup.name.object_id  # => false

    ##
    # :method: dup
    # Duped objects have no id assigned and are treated as new records. Note
    # that this is a "shallow" copy as it copies the object's attributes
    # only, not its associations. The extent of a "deep" copy is application
    # specific and is therefore left to the application to implement according
    # to its need.
    # The dup method does not preserve the timestamps (created|updated)_(at|on).

    ##
    def initialize_dup(other) # :nodoc:
      @attributes = @attributes.dup
      @attributes.reset(self.class.primary_key)

      run_callbacks(:initialize)

      @new_record  = true
      @destroyed   = false

      super
    end

    # Populate +coder+ with attributes about this record that should be
    # serialized. The structure of +coder+ defined in this method is
    # guaranteed to match the structure of +coder+ passed to the +init_with+
    # method.
    #
    # Example:
    #
    #   class Post < ActiveRecord::Base
    #   end
    #   coder = {}
    #   Post.new.encode_with(coder)
    #   coder # => {"attributes" => {"id" => nil, ... }}
    def encode_with(coder)
      # FIXME: Remove this when we better serialize attributes
      coder['raw_attributes'] = attributes_before_type_cast
      coder['attributes'] = @attributes
      coder['new_record'] = new_record?
      coder['active_record_yaml_version'] = 1
    end

    # Returns true if +comparison_object+ is the same exact object, or +comparison_object+
    # is of the same type and +self+ has an ID and it is equal to +comparison_object.id+.
    #
    # Note that new records are different from any other record by definition, unless the
    # other record is the receiver itself. Besides, if you fetch existing records with
    # +select+ and leave the ID out, you're on your own, this predicate will return false.
    #
    # Note also that destroying a record preserves its ID in the model instance, so deleted
    # models are still comparable.
    def ==(comparison_object)
      super ||
        comparison_object.instance_of?(self.class) &&
        !id.nil? &&
        comparison_object.id == id
    end
    alias :eql? :==

    # Delegates to id in order to allow two records of the same type and id to work with something like:
    #   [ Person.find(1), Person.find(2), Person.find(3) ] & [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
    def hash
      if id
        id.hash
      else
        super
      end
    end

    # Clone and freeze the attributes hash such that associations are still
    # accessible, even on destroyed records, but cloned models will not be
    # frozen.
    def freeze
      @attributes = @attributes.clone.freeze
      self
    end

    # Returns +true+ if the attributes hash has been frozen.
    def frozen?
      @attributes.frozen?
    end

    # Allows sort on objects
    def <=>(other_object)
      if other_object.is_a?(self.class)
        self.to_key <=> other_object.to_key
      else
        super
      end
    end

    # Returns +true+ if the record is read only. Records loaded through joins with piggy-back
    # attributes will be marked as read only since they cannot be saved.
    def readonly?
      @readonly
    end

    # Marks this record as read only.
    def readonly!
      @readonly = true
    end

    def connection_handler
      self.class.connection_handler
    end

    # Returns the contents of the record as a nicely formatted string.
    def inspect
      # We check defined?(@attributes) not to issue warnings if the object is
      # allocated but not initialized.
      inspection = if defined?(@attributes) && @attributes
                     self.class.column_names.collect { |name|
                       if has_attribute?(name)
                         "#{name}: #{attribute_for_inspect(name)}"
                       end
                     }.compact.join(", ")
                   else
                     "not initialized"
                   end
      "#<#{self.class} #{inspection}>"
    end

    # Takes a PP and prettily prints this record to it, allowing you to get a nice result from `pp record`
    # when pp is required.
    def pretty_print(pp)
      return super if custom_inspect_method_defined?
      pp.object_address_group(self) do
        if defined?(@attributes) && @attributes
          column_names = self.class.column_names.select { |name| has_attribute?(name) || new_record? }
          pp.seplist(column_names, proc { pp.text ',' }) do |column_name|
            column_value = read_attribute(column_name)
            pp.breakable ' '
            pp.group(1) do
              pp.text column_name
              pp.text ':'
              pp.breakable
              pp.pp column_value
            end
          end
        else
          pp.breakable ' '
          pp.text 'not initialized'
        end
      end
    end

    # Returns a hash of the given methods with their names as keys and returned values as values.
    def slice(*methods)
      Hash[methods.map! { |method| [method, public_send(method)] }].with_indifferent_access
    end

    private

    # Under Ruby 1.9, Array#flatten will call #to_ary (recursively) on each of the elements
    # of the array, and then rescues from the possible NoMethodError. If those elements are
    # ActiveRecord::Base's, then this triggers the various method_missing's that we have,
    # which significantly impacts upon performance.
    #
    # So we can avoid the method_missing hit by explicitly defining #to_ary as nil here.
    #
    # See also http://tenderlovemaking.com/2011/06/28/til-its-ok-to-return-nil-from-to_ary.html
    def to_ary # :nodoc:
      nil
    end

    def init_internals
      @readonly                 = false
      @destroyed                = false
      @marked_for_destruction   = false
      @destroyed_by_association = nil
      @new_record               = true
      @txn                      = nil
      @_start_transaction_state = {}
      @transaction_state        = nil
    end

    def initialize_internals_callback
    end

    def thaw
      if frozen?
        @attributes = @attributes.dup
      end
    end

    def custom_inspect_method_defined?
      self.class.instance_method(:inspect).owner != ActiveRecord::Base.instance_method(:inspect).owner
    end
  end
end

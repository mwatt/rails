require 'active_record/scoping/default'
require 'active_record/scoping/named'

module ActiveRecord
  # This class is used to create a table that keeps track of which migrations
  # have been applied to a given database. When a migration is run, its schema
  # number is inserted in to the `SchemaMigration.table_name` so it doesn't need
  # to be executed the next time.
  #
  # Table also stores the current environment that was used when a migration was
  # present. This could be useful for ensuring data is not accidentally removed from
  # a production database when running tests with production credentials.
  class SchemaMigration < ActiveRecord::Base
    class << self
      def primary_key
        nil
      end

      def table_name
        "#{table_name_prefix}#{ActiveRecord::Base.schema_migrations_table_name}#{table_name_suffix}"
      end

      def index_name
        "#{table_name_prefix}unique_#{ActiveRecord::Base.schema_migrations_table_name}#{table_name_suffix}"
      end

      def table_exists?
        connection.table_exists?(table_name)
      end

      # Creates a schema table with columns +environment+ and +version+
      def create_table(limit=nil)
        if table_exists?
          return if environment_is_stored?
          connection.change_table(table_name) do |t|
            t.add_column :environment, :string
            t.timestamps
          end
        else
          version_options = {null: false}
          version_options[:limit] = limit if limit

          connection.create_table(table_name, id: false) do |t|
            t.column :version,     :string, version_options
            t.column :environment, :string
            t.timestamps
          end
          connection.add_index table_name, :version, unique: true, name: index_name
        end
      end

      def environment_is_stored?
        column_names.include?("environment")
      end

      def drop_table
        if table_exists?
          connection.remove_index table_name, name: index_name
          connection.drop_table(table_name)
        end
      end

      def normalize_migration_number(number)
        "%.3d" % number.to_i
      end

      def normalized_versions
        pluck(:version).map { |v| normalize_migration_number v }
      end
    end

    def version
      super.to_i
    end
  end
end

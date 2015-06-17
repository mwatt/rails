module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module ReferentialIntegrity # :nodoc:
        def supports_disable_referential_integrity? # :nodoc:
          true
        end

        def disable_referential_integrity # :nodoc:
          if supports_disable_referential_integrity?
            tables_constraints = execute(<<-SQL).values
              SELECT table_name, constraint_name
              FROM information_schema.table_constraints
              WHERE constraint_type = 'FOREIGN KEY'
              AND is_deferrable = 'NO'
              AND table_name IN (#{tables.collect { |name| quote(name) }.join(",")})
            SQL

            execute(
              tables_constraints.collect { |table, constraint|
                "ALTER TABLE #{quote_table_name(table)} ALTER CONSTRAINT #{constraint} DEFERRABLE"
              }.join(";")
            )

            begin
              transaction do
                execute('SET CONSTRAINTS ALL DEFERRED')

                yield
              end
            ensure
              execute(
                tables_constraints.collect { |table, constraint|
                  "ALTER TABLE #{quote_table_name(table)} ALTER CONSTRAINT #{constraint} NOT DEFERRABLE"
                }.join(";")
              )
            end
          else
            yield
          end
        end
      end
    end
  end
end

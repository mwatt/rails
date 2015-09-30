module Rails
  module Commands
    class Db < Command
      set_banner :db_migrate 'Run pending migrations for database'
      rake_delegate 'db:migrate'
    end
  end
end

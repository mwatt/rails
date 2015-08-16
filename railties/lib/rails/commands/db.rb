module Rails
  module Commands
    class Db < Command
      options_for :db_migrate do |opts, _|
        opts.banner = 'Run pending migrations for database'
      end

      rake_delegate 'db:migrate'
    end
  end
end

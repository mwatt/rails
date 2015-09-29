require 'rails/commands/command'
require 'rake'

module Rails
  module Commands
    # This is a wrapper around all Rails assets tasks, including:
    #   rails assets:clean
    #   rails assets:clobber
    #   rails assets:environment
    #   rails assets:precompile
    class Assets < Command
      rake_delegate 'assets:clean', 'assets:clobber', 'assets:environment',
        'assets:precompile'
    end
  end
end

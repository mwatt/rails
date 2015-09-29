require 'rails/commands/command'
require 'rake'

module Rails
  module Commands
    # This is a wrapper around the Rails dev:cache command
    class DevCache < Command
      rake_delegate 'dev:cache'
    end
  end
end

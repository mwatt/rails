require 'rails/commands/command'

module Rails
  module Commands
    # This is a wrapper around the Rails dev:cache command
    class DevCache < Command
      options_for :dev_cache do |opts, _|
        opts.banner = 'Toggle development mode caching on/off'
      end

      def dev_cache
        if File.exist? 'tmp/caching-dev.txt'
          File.delete 'tmp/caching-dev.txt'
          puts 'Development mode is no longer being cached.'
        else
          FileUtils.touch 'tmp/caching-dev.txt'
          puts 'Development mode is now being cached.'
        end

        FileUtils.touch 'tmp/restart.txt'
      end
    end
  end
end

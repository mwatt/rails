module Rails
  module Commands
    # This is a wrapper around all Rails tmp tasks, including:
    #   rails tmp:clear
    #   rails tmp:create
    class Tmp < Command
      def tmp_clear
        system("bin/rake tmp:clear")
      end

      def tmp_create
        system("bin/rake tmp:create")
      end
    end
  end
end

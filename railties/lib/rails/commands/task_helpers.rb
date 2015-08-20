module Rails
  module Commands
    # This module is a set of common tools to be used between Command
    # objects. 
    module TaskHelpers
      def shift_argv!
        argv.shift if argv.first && argv.first[0] != '-'
      end
    end
  end
end

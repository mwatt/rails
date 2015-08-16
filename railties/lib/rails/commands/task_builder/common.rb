module Rails
  module Commands
    module TaskBuilder
      # This module is a set of common tools to be used between TaskBuilder
      # objects. 
      module Common
        def shift_argv!
          argv.shift if argv.first && argv.first[0] != '-'
        end
      end
    end
  end
end

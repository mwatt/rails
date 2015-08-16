module Rails
  module Commands
    # This is a wrapper around all Rails tmp tasks, including:
    #   rails tmp:clear
    #   rails tmp:create
    class Tmp < Command
      rake_delegate 'tmp:clear', 'tmp:create'
    end
  end
end

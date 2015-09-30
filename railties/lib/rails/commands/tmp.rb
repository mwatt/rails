module Rails
  module Commands
    # This is a wrapper around all Rails tmp tasks, including:
    #   rails tmp:clear
    #   rails tmp:create
    class Tmp < Command
      set_banner :tmp_clear, ''
      set_banner :tmp_create, ''

      rake_delegate 'tmp:clear', 'tmp:create'
    end
  end
end

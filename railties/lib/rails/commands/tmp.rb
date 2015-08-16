module Rails
  module Commands
    # This is a wrapper around all Rails tmp tasks, including:
    #   rails tmp:clear
    #   rails tmp:create
    class Tmp < Command
      set_banner :tmp_clear, ''
      set_banner :tmp_create, ''
      set_banner :tmp_sessions_clear, ''
      set_banner :tmp_cache_clear, ''
      set_banner :tmp_sockets_clear, ''

      rake_delegate 'tmp:clear', 'tmp:create', 'tmp:sessions:clear', 'tmp:cache:clear', 'tmp:sockets:clear'
    end
  end
end

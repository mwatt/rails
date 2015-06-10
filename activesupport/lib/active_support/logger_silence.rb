require 'active_support/concern'

module LoggerSilence
  extend ActiveSupport::Concern

  included do
    cattr_accessor :silencer, :local_levels
    self.silencer     = true
    self.local_levels = {}
  end

  def local_log_id
    [Thread.current.__id__, self.__id__].hash
  end

  def level
    return super unless local_levels[local_log_id]
    local_levels[local_log_id]
  end

  # Silences the logger for the duration of the block.
  def silence(temporary_level = Logger::ERROR)
    if silencer
      begin
        old_local_level            = local_levels[local_log_id]
        local_levels[local_log_id] = temporary_level

        yield self
      ensure
        if old_local_level
          local_levels[local_log_id] = old_local_level
        else
          local_levels.delete(local_log_id)
        end
      end
    else
      yield self
    end
  end
end
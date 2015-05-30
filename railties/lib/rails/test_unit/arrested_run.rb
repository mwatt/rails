module Rails
  module ArrestedRun
    def run
      Minitest.run_arrested ? self : super
    rescue Interrupt => e
      Minitest.run_arrested = true
    end
  end
end

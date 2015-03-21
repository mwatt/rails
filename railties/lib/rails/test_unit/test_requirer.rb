module Rails
  module TestRequirer
    def self.require_tests(patterns)
      files = patterns.map do |arg|
        arg = arg.gsub(':', '')
        Dir.exist?(arg) ? "#{arg}/**/*_test.rb" : arg
      end

      Rake::FileList[files.presence || 'test/**/*_test.rb'].to_a.each do |file|
        require File.expand_path(file)
      end
    end
  end
end

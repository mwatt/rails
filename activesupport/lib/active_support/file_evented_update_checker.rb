require 'listen'

module ActiveSupport
  class FileEventedUpdateChecker
    attr_reader :listener
    def initialize(files, directories={}, &block)
      @files = Set.new
      @files = files.map { |f| File.expand_path(f)}
      @dirs = Hash.new
      directories.each do |key,value|
        @dirs[File.expand_path(key)] = Array(value) if !Array(value).empty?
      end
      @block = block
      @modified = false
      watch_dirs = base_directories
      @listener = Listen.to(*watch_dirs,&method(:changed)) if !watch_dirs.empty?
      @listener.start if @listener
    end

    def updated?
      @modified
    end

    def execute
      @block.call
    ensure
      @modified = false
    end

    # Execute the block given if updated.
    def execute_if_updated
      if updated?
        execute
        true
      else
        false
      end
    end

    def watching?(file)
      return true if @files.include?(file)
      cfile = file
      while !cfile.eql? "/"
        cfile = File.expand_path("#{cfile}/..")
        if !@dirs[cfile].nil? and file.end_with?(*(@dirs[cfile].map {|ext| ".#{ext.to_s}"}))
          return true
        end
      end
      # @dirs.map do |key,value|
      # 	if file.start_with?(key) and file.end_with?(*(value.map {|ext| ".#{ext.to_s}"}))
      # 		return true
      # 	end
      # end
      false
    end

    def changed(modified, added, removed)
      return if updated?
      if (modified + added + removed).any? { |f| watching? f }
        @modified = true
      end
    end

    def base_directories
      # TODO :- To add nearest parent directory which exists for watching when watching directory does not exist.
      values = (@files.map { |f| File.expand_path("#{f}/..") if File.exist?(f) } + @dirs.keys.map {|dir| dir if File.directory?(dir)} if @dirs).uniq
      #(@files.map { |f| File.expand_path("#{f}/..") if File.exists?(f) } + @dirs.keys.map {|dir| dir if File.directory?(dir)} if @dirs).uniq
      values = values.map {|v| v if !v.nil?}
      values
    end
  end
end

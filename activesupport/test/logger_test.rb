require 'abstract_unit'
require 'multibyte_test_helpers'
require 'stringio'
require 'fileutils'
require 'tempfile'

class LoggerTest < ActiveSupport::TestCase
  include MultibyteTestHelpers

  Logger = ActiveSupport::Logger

  def setup
    @message = "A debug message"
    @integer_message = 12345
    @output  = StringIO.new
    @logger  = Logger.new(@output)
  end

  def with_level(level = Logger::INFO)
    begin
      old_level, @logger.level = @logger.level, level
      yield
    ensure
      @logger.level = old_level
    end
  end

  def level_name(level)
    ::Logger::Severity.constants.find do |severity|
      Logger.const_get(severity) == level
    end.to_s
  end

  def test_write_binary_data_to_existing_file
    t = Tempfile.new ['development', 'log']
    t.binmode
    t.write 'hi mom!'
    t.close

    f = File.open(t.path, 'w')
    f.binmode

    logger = Logger.new f
    logger.level = Logger::DEBUG

    str = "\x80"
    str.force_encoding("ASCII-8BIT")

    logger.add Logger::DEBUG, str
  ensure
    logger.close
    t.close true
  end

  def test_write_binary_data_create_file
    fname = File.join Dir.tmpdir, 'lol', 'rofl.log'
    FileUtils.mkdir_p File.dirname(fname)
    f = File.open(fname, 'w')
    f.binmode

    logger = Logger.new f
    logger.level = Logger::DEBUG

    str = "\x80"
    str.force_encoding("ASCII-8BIT")

    logger.add Logger::DEBUG, str
  ensure
    logger.close
    File.unlink fname
  end

  def test_should_log_debugging_message_when_debugging
    @logger.level = Logger::DEBUG
    @logger.add(Logger::DEBUG, @message)
    assert @output.string.include?(@message)
  end

  def test_should_not_log_debug_messages_when_log_level_is_info
    @logger.level = Logger::INFO
    @logger.add(Logger::DEBUG, @message)
    assert ! @output.string.include?(@message)
  end

  def test_should_add_message_passed_as_block_when_using_add
    @logger.level = Logger::INFO
    @logger.add(Logger::INFO) {@message}
    assert @output.string.include?(@message)
  end

  def test_should_add_message_passed_as_block_when_using_shortcut
    @logger.level = Logger::INFO
    @logger.info {@message}
    assert @output.string.include?(@message)
  end

  def test_should_convert_message_to_string
    @logger.level = Logger::INFO
    @logger.info @integer_message
    assert @output.string.include?(@integer_message.to_s)
  end

  def test_should_convert_message_to_string_when_passed_in_block
    @logger.level = Logger::INFO
    @logger.info {@integer_message}
    assert @output.string.include?(@integer_message.to_s)
  end

  def test_should_not_evaluate_block_if_message_wont_be_logged
    @logger.level = Logger::INFO
    evaluated = false
    @logger.add(Logger::DEBUG) {evaluated = true}
    assert evaluated == false
  end

  def test_should_not_mutate_message
    message_copy = @message.dup
    @logger.info @message
    assert_equal message_copy, @message
  end

  def test_should_know_if_its_loglevel_is_below_a_given_level
    Logger::Severity.constants.each do |level|
      next if level.to_s == 'UNKNOWN'
      @logger.level = Logger::Severity.const_get(level) - 1
      assert @logger.send("#{level.downcase}?"), "didn't know if it was #{level.downcase}? or below"
    end
  end

  def test_buffer_multibyte
    @logger.info(UNICODE_STRING)
    @logger.info(BYTE_STRING)
    assert @output.string.include?(UNICODE_STRING)
    byte_string = @output.string.dup
    byte_string.force_encoding("ASCII-8BIT")
    assert byte_string.include?(BYTE_STRING)
  end

  def test_silencing_everything_but_errors
    @logger.silence do
      @logger.debug "NOT THERE"
      @logger.error "THIS IS HERE"
    end

    assert !@output.string.include?("NOT THERE")
    assert @output.string.include?("THIS IS HERE")
  end

  def test_logger_thread_safety
    @logger.level = Logger::INFO

    assert @logger.level == Logger::INFO,
           "Expected level INFO, got #{level_name(@logger.level)} (before threads)"

    threads = (1..2).collect do |i|
      # stagger the threads out using sleep so that they overlap during
      # log level changes, e.g.:
      #
      #    Time | Thread_1        | Thread_2
      #   ------+-----------------+-----------------
      #    ~0.0 | 1st sleep start | 1st sleep start
      #    ~0.1 | 1st sleep end   | <sleeping>
      #    ~0.1 | #with_level()   | <sleeping>
      #    ~0.1 | 2nd sleep start | <sleeping>
      #    ~0.2 | <sleeping>      | #with_level()
      #    ~0.2 | <sleeping>      | 2nd sleep start
      #    ~0.3 | 2nd sleep end   | <sleeping>
      #    ~0.4 | <dead>          | 2nd sleep end

      Thread.new do
        sleep 0.1 * i

        assert @logger.level == Logger::INFO,
               "Expected level INFO, got #{level_name(@logger.level)} (at start of thread #{i})"

        with_level(Logger::ERROR) do
          assert @logger.level == Logger::ERROR,
                 "Expected level ERROR, got #{level_name(@logger.level)} (during with_level yield in thread #{i})"
          sleep 0.2
        end

        assert @logger.level == Logger::INFO,
              "Expected level INFO, got #{level_name(@logger.level)} (at end of thread #{i})"
      end
    end

    threads.collect(&:join)

    assert @logger.level == Logger::INFO, "Expected level INFO, got #{level_name(@logger.level)} (in main thread)"
  end
end

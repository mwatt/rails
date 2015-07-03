require 'abstract_unit'
require 'fileutils'
require 'thread'

MTIME_FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

class FileEventedUpdateCheckerWithEnumerableTest < ActiveSupport::TestCase
	FILES = %w(1.txt 2.txt 3.txt)

  def setup
    FileUtils.mkdir_p("tmp_watcher")
    FileUtils.touch(FILES)
  end

  def teardown
    FileUtils.rm_rf("tmp_watcher")
    FileUtils.rm_rf(FILES)
  end

  def test_should_not_execute_the_block_if_no_paths_are_given
    i = 0
    checker = ActiveSupport::FileEventedUpdateChecker.new([]){ i += 1 }
    checker.execute_if_updated
    assert_equal 0, i
  end

  def test_should_not_invoke_the_block_if_no_file_has_changed
    i = 0
    checker = ActiveSupport::FileEventedUpdateChecker.new(FILES){ i += 1 }
    5.times { assert !checker.execute_if_updated }
    assert_equal 0, i
  end

  def test_should_invoke_the_block_if_a_file_has_changed
    i = 0
    checker = ActiveSupport::FileEventedUpdateChecker.new(FILES){ i += 1 }
    sleep(1)
    FileUtils.touch(FILES)
    sleep(1) #extra
    assert checker.execute_if_updated
    assert_equal 1, i
  end

  def test_should_be_robust_enough_to_handle_deleted_files
    i = 0
    checker = ActiveSupport::FileEventedUpdateChecker.new(FILES){ i += 1 }
    FileUtils.rm(FILES)
    sleep(1) #extra
    assert checker.execute_if_updated
    assert_equal 1, i
  end

  def test_should_be_robust_to_handle_files_with_wrong_modified_time
    i = 0
    now = Time.now
    time = Time.mktime(now.year + 1, now.month, now.day) # wrong mtime from the future
    File.utime time, time, FILES[2]

    checker = ActiveSupport::FileEventedUpdateChecker.new(FILES){ i += 1 }

    sleep(1)
    FileUtils.touch(FILES[0..1])
    sleep(1) #extra
    assert checker.execute_if_updated
    assert_equal 1, i
  end

  def test_should_cache_updated_result_until_execute
    i = 0
    checker = ActiveSupport::FileEventedUpdateChecker.new(FILES){ i += 1 }
    assert !checker.updated?

    sleep(1)
    FileUtils.touch(FILES)
    sleep(1) #extra
    assert checker.updated?
    checker.execute
    assert !checker.updated?
  end

  def test_should_invoke_the_block_if_a_watched_dir_changed_its_glob
    i = 0
    checker = ActiveSupport::FileEventedUpdateChecker.new([], "tmp_watcher" => [:txt]){ i += 1 }
    FileUtils.cd "tmp_watcher" do
      FileUtils.touch(FILES)
    end
    sleep(2) #extra
    assert checker.execute_if_updated
    assert_equal 1, i
  end

  def test_should_not_invoke_the_block_if_a_watched_dir_changed_its_glob
    i = 0
    checker = ActiveSupport::FileEventedUpdateChecker.new([], "tmp_watcher" => :rb){ i += 1 }
    FileUtils.cd "tmp_watcher" do
      FileUtils.touch(FILES)
    end
    #sleep(2) #extra
    assert !checker.execute_if_updated
    assert_equal 0, i
  end

  def test_should_not_block_if_a_strange_filename_used
    FileUtils.mkdir_p("tmp_watcher/valid,yetstrange,path,")
    FileUtils.touch(FILES.map { |file_name| "tmp_watcher/valid,yetstrange,path,/#{file_name}" })

    test = Thread.new do
      ActiveSupport::FileEventedUpdateChecker.new([],"tmp_watcher/valid,yetstrange,path," => :txt) { i += 1 }
      Thread.exit
    end
    test.priority = -1
    test.join(5)

    assert !test.alive?
  end

  def test_base_directories
  	i = 0
  	watcher = ActiveSupport::FileEventedUpdateChecker.new(FILES){ i += 1 }
  	assert_equal watcher.base_directories, watcher.listener.directories
  	assert true
  end

  def test_modified_should_become_true_when_watched_file_is_updated
  	watcher = ActiveSupport::FileEventedUpdateChecker.new(FILES){ i += 1 }
  	assert_equal watcher.updated?, false
  	FileUtils.rm(FILES)
  	sleep 1
  	assert_equal watcher.updated?, true
  end
  
end
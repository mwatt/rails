require 'helper'
require 'jobs/kwargs_job'

class AsyncJobTest < ActiveSupport::TestCase

  def job_queue_spy
    ActiveJob::AsyncJob.const_get(:QUEUES)
  end

  def delete_all_queues
    job_queue_spy.clear
  end

  def reset_test_mode(value)
    ActiveJob::AsyncJob.instance_variable_set(:@test_mode, value)
  end

  teardown do
    reset_test_mode(true)
    delete_all_queues
  end

  test "#set_test_mode! sets test mode" do
    reset_test_mode(false)
    assert_not ActiveJob::AsyncJob.test_mode?
    ActiveJob::AsyncJob.set_test_mode!
    assert ActiveJob::AsyncJob.test_mode?
  end

  test "#create_thread_pool returns a thread_pool" do
    reset_test_mode(false)
    thread_pool = ActiveJob::AsyncJob.create_thread_pool
    assert thread_pool.is_a? Concurrent::ExecutorService
    assert_not thread_pool.is_a? Concurrent::ImmediateExecutor
  end

  test "#create_thread_pool returns an ImmediateExecutor in test mode" do
    ActiveJob::AsyncJob.set_test_mode!
    thread_pool = ActiveJob::AsyncJob.create_thread_pool
    assert thread_pool.is_a? Concurrent::ImmediateExecutor
  end

  test "#create_queue creates a queue with the given name and thread pool" do
    queue_name = :test_queue
    thread_pool_stub = :thread_pool_stub
    ActiveJob::AsyncJob.create_queue(queue_name, thread_pool_stub)
    assert_equal job_queue_spy[queue_name], thread_pool_stub
  end

  test "creating a queue that already exists raises an error" do
    queue_name = :test_queue
    thread_pool_stub = :thread_pool_stub
    ActiveJob::AsyncJob.create_queue(queue_name, thread_pool_stub)
    err = assert_raises ActiveJob::AsyncJob::QueueCreationError do
      ActiveJob::AsyncJob.create_queue(queue_name, thread_pool_stub)
    end
    assert_match 'queue already exists', err.message
  end

  test "posting to a queue that does not exist creates the queue" do
    break unless ActiveJob::Base.queue_adapter == :async
    queue_name = "default"
    assert_not job_queue_spy.key? queue_name
    KwargsJob.perform_later(argument: 2)
    assert job_queue_spy.key? queue_name
  end
end

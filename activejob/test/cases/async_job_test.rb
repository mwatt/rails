require 'helper'
require 'jobs/hello_job'
require 'jobs/queue_as_job'

class AsyncJobTest < ActiveSupport::TestCase

  def using_async_adapter?
    ActiveJob::Base.queue_adapter.is_a? ActiveJob::QueueAdapters::AsyncAdapter
  end

  setup do
    ActiveJob::AsyncJob.set_normal_mode!
  end

  teardown do
    ActiveJob::AsyncJob::QUEUES.clear
    ActiveJob::AsyncJob.set_test_mode!
  end

  test "#create_thread_pool returns a thread_pool" do
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
    assert_equal ActiveJob::AsyncJob::QUEUES[queue_name], thread_pool_stub
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

  test "enqueuing without specifying a queue uses the default queue" do
    break unless using_async_adapter?
    assert_not ActiveJob::AsyncJob::QUEUES.key? 'default'
    HelloJob.perform_later
    assert ActiveJob::AsyncJob::QUEUES.key? 'default'
  end

  test "enqueuing to a queue that does not exist creates the queue" do
    break unless using_async_adapter?
    assert_not ActiveJob::AsyncJob::QUEUES.key? QueueAsJob::MY_QUEUE.to_s
    QueueAsJob.perform_later
    assert ActiveJob::AsyncJob::QUEUES.key? QueueAsJob::MY_QUEUE.to_s
  end
end

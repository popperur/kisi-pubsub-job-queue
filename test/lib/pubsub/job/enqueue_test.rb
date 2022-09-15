require("test_helper")
require("minitest/autorun")
require("mocha/minitest")

describe(Pubsub::Job::Enqueue) do
  let(:job_enqueue) { Pubsub::Job::Enqueue.new(logger: Logger.new("/dev/null")) }

  before do
    job_enqueue.immediate = true
  end

  it("can enqueue a job") do
    message = job_enqueue.enqueue(MockJob.new.serialize)
    expect(message.attributes["scheduled_at"]).wont_be_nil
  end

  it("can enqueue a job to the default queue") do
    mock_queue = mock()
    mock_queue.expects(:publish)
    job_enqueue.expects(:queue).with("default").returns(mock_queue)
    job_enqueue.enqueue(MockJob.new.serialize)
  end

  it("can enqueue a job to a specific queue") do
    mock_queue = mock()
    mock_queue.expects(:publish)
    job_enqueue.expects(:queue).with("serial").returns(mock_queue)
    job_enqueue.enqueue(MockJob.new.serialize, queue_name: "serial")
  end

  it("can enqueue a job to be performed in the future") do
    timestamp = (Time.now + 10.seconds).to_f
    message = job_enqueue.enqueue(MockJob.new.serialize, scheduled_at: timestamp)
    # verify if timestamp is stored as a message attribute
    expect(message.attributes["scheduled_at"]).wont_be_nil
    expect(message.attributes["scheduled_at"].to_f).must_equal(timestamp)
  end

end

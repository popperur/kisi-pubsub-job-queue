require("test_helper")
require("minitest/autorun")

describe(Pubsub::Job::Enqueue) do
  let(:handler) { Pubsub::Job::Enqueue.new }

  it("enqueues a job") do
    handler.immediate = true
    message = handler.enqueue(MockJob.new.serialize)
    expect(message.attributes["scheduled_at"]).wont_be_nil
  end

  it("enqueues a job to a specific queue") do
    handler.immediate = true
    message = handler.enqueue(MockJob.new.serialize, queue_name: "serial")
    expect(message.attributes["scheduled_at"]).wont_be_nil
  end

  it("enqueues a job to be performed in the future") do
    handler.immediate = true
    timestamp = (Time.now + 10.seconds).to_f
    message = handler.enqueue(MockJob.new.serialize, scheduled_at: timestamp)
    # verify if timestamp is stored as a message attribute
    expect(message.attributes["scheduled_at"]).wont_be_nil
    expect(message.attributes["scheduled_at"].to_f).must_equal(timestamp)
  end

end

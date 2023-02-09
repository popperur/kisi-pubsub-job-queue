# frozen_string_literal: true

require("test_helper")
require("minitest/autorun")
require("mocha/minitest")

describe(Pubsub::Job::Executor) do
  let(:pubsub_client) { Pubsub::Client.new }
  let(:job_executor) { Pubsub::Job::Executor.new(logger: Logger.new("/dev/null")) }
  let(:job_data) { MockJob.new.serialize }

  describe("with acknowledging the message") do
    let(:rec_msg) { rec_message(job_data.to_json) }

    before do
      rec_msg.expects(:acknowledge!)
    end

    it("can execute a job") do
      job_executor.expects(:execute_job)
      job_executor.process(rec_msg)
    end

    it("can lock a job") do
      job_executor.expects(:lock_job)
      job_executor.process(rec_msg)
    end

    it("can unlock a job") do
      job_executor.expects(:unlock_job)
      job_executor.process(rec_msg)
    end

  end

  it("can delay a job execution") do
    rec_msg = rec_message(job_data.to_json, attributes: { scheduled_at: (Time.now + 5.minutes).to_f.to_s })
    rec_msg.expects(:modify_ack_deadline!)
    job_executor.process(rec_msg)
  end

  it("can move the job to the morgue queue") do
    job = MockJob.new(raise_error: true)
    # simulate 3 failed attempts
    job.executions = 3
    job.exception_executions = { "[JobError]" => 3 }
    job_data = job.serialize
    rec_message = rec_message(job_data.to_json)
    rec_message.stubs(:acknowledge!)
    job_executor.expects(:move_job_to_morgue)
    job_executor.process(rec_message)
  end

  it("can stop processing for an invalid job") do
    rec_msg = rec_message("not a valid job data")
    job_executor.expects(:execute_job).never
    job_executor.process(rec_msg)
  end

  # Creates a fake {Google::Cloud::PubSub::ReceivedMessage} from the job data.
  # @param data [String] The job data.
  # @param attributes [Hash] The message attributes.
  # @return [Google::Cloud::PubSub::ReceivedMessage] The created message object.
  def rec_message(data, attributes: {})
    subscription = pubsub_client.subscription("default")
    hash = rec_message_hash(data, attributes: attributes)
    message_grpc = Google::Cloud::PubSub::V1::ReceivedMessage.new(hash)
    Google::Cloud::PubSub::ReceivedMessage.from_grpc(message_grpc, subscription)
  end

  # stolen from google-cloud-pubsub/test/helper.rb
  def rec_message_hash(data, id: rand(1_000_000), attributes: {})
    {
      ack_id: "ack-id-#{id}",
      delivery_attempt: 10,
      message: {
        data: data,
        attributes: attributes,
        message_id: "msg-id-#{id}"
      }
    }
  end

end


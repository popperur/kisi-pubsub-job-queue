# frozen_string_literal: true

require("test_helper")
require("minitest/autorun")
require("mocha/minitest")

describe(Pubsub::Job::Executor) do
  let(:pubsub_client) { Pubsub::Client.new }

  it("acknowledges message, and executes the job") do
    job_data = MockJob.new.serialize
    message = rec_message(job_data.to_json)
    message.expects(:acknowledge!)

    assert_process_output(message, /Executing MockJob/)
  end

  it("delays the job execution if needed") do
    job_data = MockJob.new.serialize
    message = rec_message(job_data.to_json, attributes: { scheduled_at: (Time.now + 5.minutes).to_f.to_s })
    message.expects(:modify_ack_deadline!)

    assert_process_output(message, /was delayed for 300 seconds/)
  end

  it("moves the job to the morgue queue after 3 unsuccessful attempt") do
    job = MockJob.new(raise_error: true)
    # simulate 3 failed attempts
    job.executions = 3
    job.exception_executions = { "[JobError]" => 3 }
    job_data = job.serialize
    message = rec_message(job_data.to_json)
    message.expects(:acknowledge!)

    assert_process_output(message, /Moving job to morgue/)
  end

  it("acknowledges message, but logs error in case of an invalid json message") do
    message = rec_message("not a valid json")
    message.expects(:acknowledge!)

    assert_process_output(message, /Parsing the message data failed/)
  end

  def assert_process_output(message, expected_out)
    assert_output(expected_out) do
      job_executor = Pubsub::Job::Executor.new
      job_executor.immediate = true
      job_executor.process(message)
    end
  end

  # Creates a fake {Google::Cloud::PubSub::ReceivedMessage} from the job data.
  #
  # @param data [String] The job data.
  # @param attributes [Hash] The message attributes.
  # @return [Google::Cloud::PubSub::ReceivedMessage]
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


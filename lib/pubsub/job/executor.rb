# frozen_string_literal: true

require("concurrent")

module Pubsub
  module Job

    # == Pubsub Job Executor
    #
    # Includes methods for a executing a job received from Pub/Sub
    class Executor

      QUEUE_MORGUE = "morgue"

      DEFAULT_EXECUTOR_OPTIONS = {
        min_threads: 0,
        max_threads: Concurrent.processor_count,
        auto_terminate: true,
        idletime: 60, # 1 minute
        max_queue: 0, # unlimited
        fallback_policy: :caller_runs # shouldn't matter -- 0 max queue
      }.freeze

      # Used for the test suite.
      attr_writer(:immediate)

      # Initializes the object.
      #
      # @param logger [Logger] logger to use. Defaults to 'stdout'.
      # @param executor_options [Hash] executor options, see {Concurrent::ThreadPoolExecutor}[https://ruby-concurrency.github.io/concurrent-ruby/master/Concurrent/ThreadPoolExecutor.html].
      def initialize(logger: Logger.new($stdout), executor_options: {})
        @async_executor = Concurrent::ThreadPoolExecutor.new(DEFAULT_EXECUTOR_OPTIONS.merge(executor_options))
        @logger = logger
        @immediate = false
      end

      # Processes the message received from Pub/Sub
      #
      # @param message [Google::Cloud::PubSub::ReceivedMessage] The Pub/Sub message containing the job to process.
      def process(message)
        @logger.info("Message \"#{message.message_id}\" received.")
        if @immediate
          process_message(message)
        else
          Concurrent::Promises.future_on(@async_executor, message) do |async_message|
            process_message(async_message)
          end
        end
      end

      private

      # Processes the message received from Pub/Sub
      #
      # @param message [Google::Cloud::PubSub::ReceivedMessage] The Pub/Sub message containing the job to process.
      def process_message(message)
        current_time = Time.now.to_f
        scheduled_at = message.attributes["scheduled_at"].to_f
        current_time > scheduled_at ? execute(message) : delay(message, current_time, scheduled_at)
      end

      # Executes the job
      #
      # @param message [Google::Cloud::PubSub::ReceivedMessage] The Pub/Sub message containing the job to execute.
      def execute(message)
        # Notify pub/sub that there is no need for redelivery.
        # If the job fails to execute, the ActiveJob engine will enqueue it again.
        message.acknowledge!
        @logger.info("Message \"#{message.message_id}\" acknowledged.")

        job_data = extract_job_data(message)
        return unless job_data

        begin
          @logger.info("Processing job \"#{job_data['job_id']}\"..")
          ActiveJob::Base.execute(job_data)
        rescue StandardError
          # error is raised only when the job could not be processed for a certain number of attempts,
          # (specified by the retry_on parameter of the job), so we'll reassign the job to the Morgue queue.
          job_enqueue.enqueue(job_data, queue_name: QUEUE_MORGUE)
          @logger.info("Moving job to morgue \"#{job_data['job_id']}\".")
        end
      end

      # Delays the job
      #
      # @param message [Google::Cloud::PubSub::ReceivedMessage] The Pub/Sub message containing the job to delay.
      # @param current_time [Float] The current time.
      # @param scheduled_at [Float] The time when the job should be executed.
      def delay(message, current_time, scheduled_at)
        delay_in_sec = (scheduled_at - current_time).ceil.to_i
        message.modify_ack_deadline!(delay_in_sec)
        @logger.info("Message \"#{message.message_id}\" was delayed for #{delay_in_sec} seconds.")
      end

      # Extracts the job data from the message

      # @param message [Google::Cloud::PubSub::ReceivedMessage] The Pub/Sub message.
      # @return [Hash, nil] The extracted job data, or nil if the message data could not be parsed
      def extract_job_data(message)
        JSON.parse(message.data)
      rescue JSON::ParserError => e
        @logger.error("Parsing the message data failed, error: #{e.message}")
        @logger.error("Message: #{message.inspect}")
        nil
      end

      # Retrieves the pubsub job enqueue
      # @return [Pubsub::Job::Enqueue] The pubsub job enqueue.
      def job_enqueue
        @job_enqueue ||= Pubsub::Job::Enqueue.new(logger: @logger)
      end
    end
  end
end

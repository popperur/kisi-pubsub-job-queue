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
      # @param logger [Logger] logger to use. Defaults to 'stdout'.
      # @param executor_options [Hash] executor options, see {Concurrent::ThreadPoolExecutor}[https://ruby-concurrency.github.io/concurrent-ruby/master/Concurrent/ThreadPoolExecutor.html].
      def initialize(logger: Logger.new($stdout), executor_options: {})
        @async_executor = Concurrent::ThreadPoolExecutor.new(DEFAULT_EXECUTOR_OPTIONS.merge(executor_options))
        @logger = logger
        @immediate = false
        @mutex = Mutex.new
      end

      # Processes the message received from Pub/Sub
      # @param message [Google::Cloud::PubSub::ReceivedMessage] The Pub/Sub message containing the job to process.
      def process(message)
        @logger.debug("Message \"#{message.message_id}\" received.")
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
      # @param message [Google::Cloud::PubSub::ReceivedMessage] The Pub/Sub message containing the job to process.
      def process_message(message)
        current_time = Time.now.to_f
        scheduled_at = message.attributes["scheduled_at"].to_f
        current_time > scheduled_at ? execute(message) : delay(message, current_time, scheduled_at)
      end

      # Executes the job
      # @param message [Google::Cloud::PubSub::ReceivedMessage] The Pub/Sub message containing the job to execute.
      def execute(message)
        job_data = extract_job_data(message)
        return unless job_data

        job_id = job_data["job_id"]
        return if job_locked?(job_id)

        begin
          execute_job(job_data)
        rescue StandardError
          # error is raised only when the job could not be processed for a certain number of attempts,
          # (specified by the retry_on parameter of the job), so we'll reassign the job to the Morgue queue.
          move_job_to_morgue(job_data)
        end
        # we can ACK the message, the ActiveJob engine will enqueue any failed job (if retry_on kicks in).
        message.acknowledge!
        @logger.debug("Message \"#{message.message_id}\" acknowledged.")
      end

      # Delays the job
      # @param message [Google::Cloud::PubSub::ReceivedMessage] The Pub/Sub message containing the job to delay.
      # @param current_time [Float] The current time.
      # @param scheduled_at [Float] The time when the job should be executed.
      def delay(message, current_time, scheduled_at)
        delay_in_sec = (scheduled_at - current_time).ceil.to_i
        message.modify_ack_deadline!(delay_in_sec)
        @logger.debug("Message \"#{message.message_id}\" was delayed for #{delay_in_sec} seconds.")
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

      # Executes the job with {ActiveJob::Base}.
      # @param job_data {Hash} The data of the job to be executed.
      def execute_job(job_data)
        job_id = job_data["job_id"]
        lock_job(job_id)
        @logger.debug("Executing job \"#{job_id}\"..")
        ActiveJob::Base.execute(job_data)
        unlock_job(job_id)
      end

      # Moves the job to the morgue queue.
      # @param job_data {Hash} The data of the job.
      def move_job_to_morgue(job_data)
        job_enqueue.enqueue(job_data, queue_name: QUEUE_MORGUE)
        @logger.debug("Moving job \"#{job_data['job_id']}\" to the morgue queue..")
      end

      # Gets true if the job is already processing
      # @param job_id [String] The id of the job to be checked.
      # @return [Boolean] True if the job is already processing.
      def job_locked?(job_id)
        locked_job_ids.include?(job_id)
      end

      # Locks the job to avoid duplicate processing.
      # @param job_id [String] The id of the job to lock.
      def lock_job(job_id)
        @mutex.synchronize do
          locked_job_ids.add(job_id)
          @logger.debug("Job \"#{job_id}\" was locked.")
        end
      end

      # Unlocks the job to make it available for processing.
      # @param job_id [String] The id of the job to unlock.
      def unlock_job(job_id)
        @mutex.synchronize do
          locked_job_ids.delete(job_id)
          @logger.debug("Job \"#{job_id}\" was unlocked.")
        end
      end

      # Retrieves the set of locked job ids.
      # @return [Set] The set of locked job ids.
      def locked_job_ids
        @locked_job_ids ||= Set.new
      end

      # Retrieves the pubsub job enqueue
      # @return [Pubsub::Job::Enqueue] The pubsub job enqueue.
      def job_enqueue
        @job_enqueue ||= Pubsub::Job::Enqueue.new(logger: @logger)
      end
    end
  end
end

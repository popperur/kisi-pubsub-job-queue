# frozen_string_literal: true

module Pubsub
  module Job

    # == Pubsub Job Worker
    #
    # Includes methods for listening on a specific queue (Pub/Sub subscription) and executing jobs received.
    class Worker

      # Initializes the Worker.
      # @param queue_name [String] The name of the queue
      # @param logger [Logger] The logger to use. Defaults to 'stdout'.
      def initialize(queue_name, logger: Logger.new($stdout))
        @queue_name = queue_name
        @job_executor = Pubsub::Job::Executor.new(logger: logger)
        @logger = logger
      end

      # Creates a listener that listens for messages (jobs) received on the worker queue.
      # The messages contain jobs to be executed. Once message received, it's processed by the job executor.
      def listen
        sub = worker_sub
        @logger.info("Worker sub initialized, listening on the \"#{@queue_name}\" queue..")

        # Create a subscriber to listen for available messages.
        subscriber = sub.listen do |message|
          # process the message
          @job_executor.process(message)
        end

        subscriber.on_error do |exception|
          @logger.info("Exception: #{exception.class} #{exception.message}")
        end

        at_exit do
          @logger.info("Stopping worker for queue \"#{@queue_name}\"..")
          subscriber.stop!(10)
        end

        subscriber.start
      end

      # Clears the queue by pulling and acknowledging all jobs without processing them.
      # The Pub/Sub system sometimes does not return all jobs with a direct pull, so
      # the pull is repeated until all jobs are purged.
      # @param immediate [Boolean] whether to return immediately or block until
      #  messages are available. Defaults to 'false'.
      def clear(immediate: false)
        sub = worker_sub
        loop do
          @logger.info("Clearing the \"#{@queue_name}\" queue, please wait..")
          messages = sub.pull(immediate: immediate)
          break if messages.empty?

          sub.acknowledge(messages)
          @logger.info("The number of removed messages: #{messages.length}.")
        end
        @logger.info("The queue has been cleared.")
      end

      private

      # Finds or creates a queue worker subscription.
      # @return [Google::Cloud::PubSub::Subscription] The subscription instance.
      def worker_sub
        @worker_sub ||= pubsub_client.subscription(@queue_name)
      end

      # Creates or retrieves the pubsub client.
      # @return [Pubsub::Client] The pubsub client.
      def pubsub_client
        @pubsub_client ||= Pubsub::Client.new
      end

    end
  end
end

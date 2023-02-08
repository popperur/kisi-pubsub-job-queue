# frozen_string_literal: true

module Pubsub
  module Job

    # == Pubsub Job Spawner
    #
    # Spawns & enqueues MockJobs as if there is no tomorrow.
    #
    # Usage:
    # Pubsub::Job::Spawner.call(job_count: 10)
    class Spawner
      prepend(SimpleCommand)

      # Initializes the Spawner.
      # @param job_count [Integer] The number of jobs to spawn. Defaults to '5'.
      def initialize(job_count: 5)
        @job_count = job_count
      end

      # Executes the service
      def call
        @job_count.times do
          MockJob.perform_later(
            sleep_duration: rand(0..6),
            raise_error: rand(2).zero?
          )
        end
      end
    end

  end
end

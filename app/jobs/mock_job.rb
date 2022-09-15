# frozen_string_literal: true

#
# Mock job for the Kisi API Challenge. It can sleep for a while and even raise a JobError.
#
class MockJob < ApplicationJob
  queue_as(:default)

  # Performs the job
  #
  # @param sleep_duration [Integer] Sleep duration in seconds. Defaults to 0.
  # @param raise_error [Boolean] Flag to specify if the job should raise an error. Defaults to false
  # @raise [JobError] if raise_error is true
  def perform(sleep_duration: 0, raise_error: false)
    puts("Executing MockJob(#{sleep_duration}, raise_error: #{raise_error})")
    sleep(sleep_duration)
    raise(JobError, "Job failed successfully.") if raise_error
  end

end

# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Jobs should be retried at most two times at least five minutes apart
  retry_on(JobError, attempts: 3, wait: 5.minutes)
end

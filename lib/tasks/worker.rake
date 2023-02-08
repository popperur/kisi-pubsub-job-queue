# frozen_string_literal: true

namespace(:worker) do
  desc("Run the worker")
  task(run: :environment) do
    require("google/cloud/pubsub")

    puts("Worker starting on the \"#{queue_name}\" queue..")

    job_worker.listen

    # Block, letting processing threads continue in the background
    sleep
  end

  desc("Clear the queue")
  task(clear: :environment) do
    job_worker.clear
  end

  def queue_name
    @queue_name ||= ENV["QUEUE_NAME"] || "default"
  end

  def job_worker
    @job_worker ||= Pubsub::Job::Worker.new(queue_name)
  end

end

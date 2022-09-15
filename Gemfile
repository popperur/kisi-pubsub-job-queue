# frozen_string_literal: true

source("https://rubygems.org")
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby("2.7.5")

gem("google-cloud-pubsub")
gem("pry-rails")
gem("puma", "~> 5.0")
gem("rails", "~> 6.1.4", ">= 6.1.4.4")
gem("rubocop")
gem("sqlite3", "~> 1.4")

# A simple, standardized way to build and use Service Objects (aka Commands) in Ruby
gem("simple_command", github: "nebulab/simple_command")

group(:development, :test) do
  gem("byebug", platforms: %i[mri mingw x64_mingw])
end

group(:development) do
  gem("listen", "~> 3.3")
end

group(:test) do
  # Mocking and stubbing library with JMock/SchMock syntax, which allows mocking and stubbing of methods
  # on real (non-mock) classes
  gem("mocha")
end

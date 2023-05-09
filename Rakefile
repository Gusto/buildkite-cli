# frozen_string_literal: true

require "bundler/gem_tasks"
task default: %i[]

namespace :buildkite do
  task :dump_schema do
    require_relative './lib/buildkite/cli.rb'
    Buildkite::CLI.dump_schema
  end
end

# frozen_string_literal: true

require "bundler/gem_tasks"
task default: %i[]

namespace :buildkite do
  task :dump_schema do
    require "./lib/bk"
    require "graphql/client"
    GraphQL::Client.dump_schema(Bk::HTTP, "schema.json")
  end
end

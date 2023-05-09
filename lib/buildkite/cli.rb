# frozen_string_literal: true

require "zeitwerk"
require "json"
require "httparty"
require "tty-pager"
require "tty-markdown"
require "tty-spinner"
require "tty-box"
require "graphql/client"
require "graphql/client/http"
require "dry/cli"

module Buildkite
  module CLI
    class Error < StandardError; end

    VERTICAL_PIPE = "⏐"
    HORIZONTAL_PIPE = "⎯"

    # Configure GraphQL endpoint using the basic HTTP network adapter.
    HTTP = GraphQL::Client::HTTP.new("https://graphql.buildkite.com/v1") do
      def headers(context)
        unless (token = context[:access_token] || ENV["BUILDKITE_API_TOKEN"])
          raise "missing BuildKite access token"
        end

        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end
    end

    SCHEMA_PATH = Pathname.new(__FILE__).dirname.dirname.dirname.join("schema.json")
    Schema = GraphQL::Client.load_schema(SCHEMA_PATH.to_s)
    # Schema = GraphQL::Client.load_schema(HTTP)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

    def self.loader
      return @loader if defined?(@loader)
      @loader = Zeitwerk::Loader.for_gem
      @loader.inflector.inflect(
        "cli" => "CLI"
      )
      @loader
    end

    def self.dump_schema
      GraphQL::Client.dump_schema(Buildkite::CLI::HTTP, SCHEMA_PATH.to_s)
    end

    loader.setup
  end
end

# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

require "json"
require "httparty"
require "tty-pager"
require "tty-markdown"
require "tty-spinner"
require "tty-box"
require "graphql/client"
require "graphql/client/http"
require "dry/cli"
require "cgi"

require_relative "bk/version"
require 'parallel'
require 'ruby-progressbar'


module Bk
  class Error < StandardError; end

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

  SCHEMA_PATH = Pathname.new(__FILE__).dirname.dirname.join("schema.json")
  Schema = GraphQL::Client.load_schema(SCHEMA_PATH.to_s)
  # Schema = GraphQL::Client.load_schema(HTTP)
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end

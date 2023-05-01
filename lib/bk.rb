# frozen_string_literal: true

require 'json'
require 'httparty'
require 'tty-pager'
require 'tty-markdown'
require 'tty-spinner'
require_relative "bk/version"

module Bk
  class Error < StandardError; end


  BUILD_ANNOTIONS_QUERY = <<-GRAPHQL
    query {
      build(slug: "%<slug>s") {
        number
        uuid

        url
        pullRequest {
          id
        }
        state
        scheduledAt
        startedAt
        finishedAt
        canceledAt

        annotations(first: 200) {
          edges {
            node {
              context
              style
              body {
                text
              }
            }
          }
        }
      }
    }
  GRAPHQL

  class CLI
    attr_reader :spinner

    def initialize(buildkite_api_token: nil)
      @client = Client.new(buildkite_api_token: buildkite_api_token)

      @spinner = TTY::Spinner.new("Talking to Buildkite API... :spinner", clear: true, format: :dots)
    end

    def annotations(url)

      result = nil
      spinner.run("Done") do |spinner|
        result = @client.annotations(url)
      end

      build = result["data"]["build"]
      puts "Build #{build['number']}: #{build['state']}"

      annotation_edges = build['annotations']['edges']
      annotations = annotation_edges.map {|edge| edge['node'] }

      TTY::Pager.page do |page|
        annotations.each do |annotation|
          context = annotation["context"]
          page.puts TTY::Markdown.parse("# #{context}")

          style = annotation["style"]

          body = annotation["body"]["text"]
          page.write TTY::Markdown.parse(body)
          page.puts ""
        end
      end
    end
  end

  class Client
    def initialize(buildkite_api_token: nil)
      @buildkite_api_token = buildkite_api_token if buildkite_api_token
    end

    def parse_slug_from_url(url)
      # https://buildkite.com/my-org/my-pipeline/builds/1234 => my-org/my-pipeline/1234
      url.delete_prefix('https://buildkite.com/').gsub('/builds', '')
    end

    def annotations(url)
      slug = parse_slug_from_url(url)

      query = BUILD_ANNOTIONS_QUERY % {slug: slug}

      execute(query)
    end

    def execute(query)
      body = {
        query: query,
      }.to_json

      response = HTTParty.post(
        'https://graphql.buildkite.com/v1',
        body: body,
        headers: {
          'Authorization' => "Bearer #{buildkite_api_token}",
          'Content-Type' => 'application/json',
        }
      )
      body = JSON.parse(response.body)

      unless body['data']
        puts response.code
        pp body
        raise 'problem getting data back'
      end

      body
    end

    def buildkite_api_token
      return @buildkite_api_token if defined?(@buildkite_api_token)

      @buildkite_api_token = ENV['BUILDKITE_GQL_API_TOKEN']
      raise 'missing BUILDKITE_GQL_API_TOKEN' unless @buildkite_api_token && !@buildkite_api_token.empty?

      @buildkite_api_token
    end
  end
end

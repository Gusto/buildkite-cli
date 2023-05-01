# frozen_string_literal: true

require 'json'
require 'httparty'
require 'tty-pager'
require 'tty-markdown'
require_relative "bk/version"

module Bk
  class Error < StandardError; end

  def initialize(buildkite_api_token: nil)
    @buildkite_api_token = buildkite_api_token if buildkite_api_token
  end


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

  class Client
    def parse_slug_from_url(url)
      # https://buildkite.com/my-org/my-pipeline/builds/1234 => my-org/my-pipeline/1234
      url.delete_prefix('https://buildkite.com/').gsub('/builds', '')
    end

    def annotations(url)
      slug = parse_slug_from_url(url)
      puts "#{url} => #{slug}"

      query = BUILD_ANNOTIONS_QUERY % {slug: slug}

      result = execute(query)

      annotation_edges = result['data']['build']['annotations']['edges']
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

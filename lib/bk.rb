# frozen_string_literal: true

require 'json'
require 'httparty'
require 'tty-pager'
require 'tty-markdown'
require 'tty-spinner'
require 'tty-box'
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
    attr_reader :spinner, :pastel

    def initialize(buildkite_api_token: nil)
      @client = Client.new(buildkite_api_token: buildkite_api_token)
      @pastel = Pastel.new

      @success_color = @pastel.green.detach
      @error_color = @pastel.red.detach
      @warning_color = @pastel.yellow.detach
      @info_color = @pastel.blue.detach
      @default_color = @pastel.gray.detach

      @style_color_map = Hash.new(@default_color)
      @style_color_map.merge! ({
        "SUCCESS" => @success_color,
        "ERROR" => @error_color,
        "WARNING" => @warning_color,
        "INFO" => @info_color
      })

      @spinner = TTY::Spinner.new("Talking to Buildkite API... :spinner", clear: true, format: :dots)
    end

    VERTICAL_PIPE="｜"

    def colorize(text, color)
      is_tty? ? color.(text) : text
    end

    def vertical_pipe
      is_tty? ? "#{VERTICAL_PIPE} " : ""
    end

    def is_tty?
      $stdout.tty?
    end

    def annotations(url)

      result = nil
      spinner.run("Done") do |spinner|
        result = @client.annotations(url)
      end

      TTY::Pager.page do |page|
        build = result["data"]["build"]
        started_at = Time.parse(build['startedAt'])
        finished_at = Time.parse(build['finishedAt']) if build['finishedAt']

        page.puts "Build #{build['number']}: #{build['state']}"
        if build['state'] == 'RUNNING' || build['state'] == 'FAILING'
          duration = Time.now - started_at
          minutes = (duration/60).to_i
          seconds = (duration%60).to_i
          page.puts "running for #{minutes}m #{seconds}s"
        elsif finished_at
          page.puts "finished at #{finished_at}"
        end
        page.puts TTY::Markdown.parse("---")

        annotation_edges = build['annotations']['edges']
        annotations = annotation_edges.map {|edge| edge['node'] }

        annotations.each do |annotation|
          style = annotation["style"]
          color = @style_color_map[style]

          context = annotation['context']
          page.puts color.("#{vertical_pipe}#{context}")
          page.puts color.(vertical_pipe)

          body = annotation['body']['text']
          output = TTY::Markdown.parse(body)
          output.each_line do |line|
            page.puts "#{color.(vertical_pipe)}  #{line}"
          end
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

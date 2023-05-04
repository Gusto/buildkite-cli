# frozen_string_literal: true

require "json"
require "httparty"
require "tty-pager"
require "tty-markdown"
require "tty-spinner"
require "tty-box"
require "graphql/client"
require "graphql/client/http"
require "git"
require_relative "bk/version"

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

  class CLI
    BuildAnnotationsQuery = Client.parse <<-GRAPHQL
      query($slug: ID!) {
        build(slug: $slug) {
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

    attr_reader :spinner, :pastel

    def initialize(buildkite_api_token: nil)
      @pastel = Pastel.new
      @g = Git.open(Dir.pwd)

      @success_color = @pastel.green.detach
      @error_color = @pastel.red.detach
      @warning_color = @pastel.yellow.detach
      @info_color = @pastel.blue.detach
      @default_color = @pastel.gray.detach

      @style_color_map = Hash.new(@default_color)
      @style_color_map.merge!({
        "SUCCESS" => @success_color,
        "ERROR" => @error_color,
        "WARNING" => @warning_color,
        "INFO" => @info_color
      })

      @spinner = TTY::Spinner.new("Talking to Buildkite API... :spinner", clear: true, format: :dots)
    end

    VERTICAL_PIPE = "｜"

    def colorize(text, color)
      is_tty? ? color.call(text) : text
    end

    def vertical_pipe
      is_tty? ? "#{VERTICAL_PIPE} " : ""
    end

    def is_tty?
      $stdout.tty?
    end

    def parse_slug_from_url(url)
      # https://buildkite.com/my-org/my-pipeline/builds/1234 => my-org/my-pipeline/1234
      url.delete_prefix("https://buildkite.com/").gsub("/builds", "")
    end

    def determine_slug
      output = `gh pr checks`
      output.lines.each do |line|
        if line =~ %r{https://buildkite.com/([^/]+)/([^/]+)/builds/(\d+)}
          return "#{$1}/#{$2}/#{$3}"
        end
      end
      nil
    end

    def annotations(url = nil)
      slug = if url
        parse_slug_from_url(url)
      else
        determine_slug
      end
      unless slug
        raise ArgumentError, "Unable to figure out slug to use"
      end

      result = nil
      spinner.run("Done") do |spinner|
        result = Client.query(BuildAnnotationsQuery, variables: {slug: slug})
      end

      TTY::Pager.page do |page|
        build = result.data.build
        started_at = Time.parse(build.started_at)
        finished_at = Time.parse(build.finished_at) if build.finished_at

        page.puts "Build #{build.number}: #{build.state}"
        if build.state == "RUNNING" || build.state == "FAILING"
          duration = Time.now - started_at
          minutes = (duration / 60).to_i
          seconds = (duration % 60).to_i
          page.puts "running for #{minutes}m #{seconds}s"
        elsif finished_at
          page.puts "finished at #{finished_at}"
        end
        page.puts TTY::Markdown.parse("---")

        annotation_edges = build.annotations.edges
        annotations = annotation_edges.map { |edge| edge.node }

        annotations.each do |annotation|
          style = annotation.style
          color = @style_color_map[style]

          context = annotation.context
          page.puts color.call("#{vertical_pipe}#{context}")
          page.puts color.call(vertical_pipe)

          body = annotation.body.text
          output = TTY::Markdown.parse(body)
          output.each_line do |line|
            page.puts "#{color.call(vertical_pipe)}  #{line}"
          end
        end
      end
    end
  end
end

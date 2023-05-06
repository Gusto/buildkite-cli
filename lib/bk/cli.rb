module Bk
  module CLI
    VERTICAL_PIPE = "⏐"
    HORIZONTAL_PIPE = "⎯"

    module Commands
      extend Dry::CLI::Registry

      class Base < Dry::CLI::Command
        attr_reader :spinner, :pastel

        def initialize(buildkite_api_token: nil)
          @pastel = Pastel.new

          @spinner = TTY::Spinner.new("Talking to Buildkite API... :spinner", clear: true, format: :dots)
        end

        def colorize(text, color)
          is_tty? ? color.call(text) : text
        end

        def vertical_pipe
          is_tty? ? "#{VERTICAL_PIPE} " : ""
        end

        def is_tty?
          $stdout.tty?
        end

        def color_map
          return @color_map if defined?(@color_map)

          success_color = @pastel.green.detach
          error_color = @pastel.red.detach
          warning_color = @pastel.yellow.detach
          info_color = @pastel.blue.detach
          default_color = @pastel.gray.detach

          @color_map = Hash.new(default_color)
          @color_map.merge!({
            # annotations style
            "SUCCESS" => success_color,
            "ERROR" => error_color,
            "WARNING" => warning_color,
            "INFO" => info_color,

            # build state
            "FAILED" => error_color
          })

          @color_map
        end

        private

        def parse_slug_from_url(url)
          # https://buildkite.com/my-org/my-pipeline/builds/1234 => my-org/my-pipeline/1234
          url.delete_prefix("https://buildkite.com/").gsub("/builds", "")
        end

        def determine_slug(url_or_slug = nil)
          if url_or_slug
            if url_or_slug.start_with?("https:")
              parse_slug_from_url(url_or_slug)
            else
              url_or_slug
            end
          else
            output = `gh pr checks`
            output.lines.each do |line|
              if line =~ %r{https://buildkite.com/([^/]+)/([^/]+)/builds/(\d+)}
                return "#{$1}/#{$2}/#{$3}"
              end
            end

            nil
          end
        end

        def query(graphql_query, **kwargs)
          result = nil
          spinner.run("Done") do |spinner|
            result = Client.query(graphql_query, **kwargs)
          end

          result
        end

        def build_header(build, io: )
          started_at = Time.parse(build.started_at)
          finished_at = Time.parse(build.finished_at) if build.finished_at

          build_color = color_map[build.state]

          io.puts "#{build_color.call(vertical_pipe)}#{build.pipeline.slug} / #{build.branch}"
          io.puts build_color.call(vertical_pipe)
          io.puts "#{build_color.call(vertical_pipe)}    #{build.message}"
          io.puts build_color.call(vertical_pipe)
          io.puts "#{build_color.call(vertical_pipe)}Build ##{build.number}: #{build.state}"

          if build.state == "RUNNING" || build.state == "FAILING"
            duration = Time.now - started_at
            minutes = (duration / 60).to_i
            seconds = (duration % 60).to_i
            io.puts "running for #{minutes}m #{seconds}s"
          elsif finished_at
            duration = finished_at - started_at
            io.puts "#{build_color.call(vertical_pipe)}#{build.state.downcase.capitalize} in #{duration}s"
          end

          io.puts ""
        end
      end

      class Annotations < Base
        desc "Show Annotations for a Build"
        argument :url_or_slug, type: :string, required: false, desc: "Build URL or Build slug"

        BuildAnnotationsQuery = Client.parse <<-GRAPHQL
          query($slug: ID!) {
            build(slug: $slug) {
              number

              pipeline {
                slug
              }

              branch
              message

              url
              pullRequest {
                id
              }
              state
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

        def call(args:, url_or_slug: nil)
          slug = determine_slug(url_or_slug)
          unless slug
            raise ArgumentError, "Unable to figure out slug to use"
          end

          result = query(BuildAnnotationsQuery, variables: {slug: slug})

          TTY::Pager.page do |page|
            build = result.data.build

            build_header(build, io: page)

            annotation_edges = build.annotations.edges
            annotations = annotation_edges.map { |edge| edge.node }

            # indent each annotation to separate it from the build status
            annotations.each_with_index do |annotation, index|
              style = annotation.style
              color = color_map[style]

              context = annotation.context
              page.puts "  #{color.call("#{vertical_pipe}#{context}")}"
              page.puts "  #{color.call(vertical_pipe)}"

              body = annotation.body.text
              output = TTY::Markdown.parse(body)
              output.each_line do |line|
                page.puts "  #{color.call(vertical_pipe)}  #{line}"
              end

              # horizontal separator between each
              unless index == annotations.length - 1
                page.puts ""
                page.puts "  #{HORIZONTAL_PIPE * (TTY::Screen.width - 4)}  "
                page.puts ""
              end
            end
          end
        end

      end

      class Artifacts < Base
        desc "Show Artifacts for a Build"
        argument :url_or_slug, type: :string, required: false, desc: "Build URL or Build slug"

        BuildArtifactsQuery = Client.parse <<-GRAPHQL
          query {
            build(slug: "gusto/zenpayroll/759716") {
              number
              message
              uuid

              branch
              pipeline {
                slug
              }

              url
              pullRequest {
                id
              }
              state
              scheduledAt
              startedAt
              finishedAt
              canceledAt

              jobs(first:10) {
                edges {
                  node {
                    __typename
                    ... on JobTypeCommand {
                      url
                      uuid
                      label
                      artifacts(first: 10) {
                        edges {
                          node {
                            state
                            path
                            downloadURL
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }

        GRAPHQL

        def call(args:, url_or_slug: nil)
          slug = determine_slug(url_or_slug)
          unless slug
            raise ArgumentError, "Unable to figure out slug to use"
          end

          result = query(BuildArtifactsQuery, variables: {slug: slug})
          build = result.data.build

          build_header(build, io: $stdout)

          jobs = build.jobs.edges.map(&:node)

          jobs.each do |job|
            puts job.label

            artifacts = job.artifacts.edges.map(&:node)

            artifacts.each do |artifact|
              puts "- #{artifact.path}"
            end
          end
        end
      end

      register "annotations", Annotations
      register "artifacts", Artifacts
    end
  end
end

module Bk
  module CLI
    VERTICAL_PIPE = "⏐"
    HORIZONTAL_PIPE = "⎯"

    module Commands
      extend Dry::CLI::Registry

      class Base < Dry::CLI::Command
        include Color

        attr_reader :spinner, :pastel

        def initialize(buildkite_api_token: nil)
          @pastel = Pastel.new

          @spinner = TTY::Spinner.new("Talking to Buildkite API... :spinner", clear: true, format: :dots)
        end

        def vertical_pipe
          is_tty? ? "#{VERTICAL_PIPE} " : ""
        end

        def is_tty?
          $stdout.tty?
        end

        def annotation_colors
          return @annotation_colors if defined?(@annotation_colors)

          @annotation_colors = create_color_hash({
            "SUCCESS" => success_color,
            "ERROR" => error_color,
            "WARNING" => warning_color,
            "INFO" => info_color
          })
        end

        def build_colors
          return @build_colors if defined?(@build_colors)
          @build_colors = create_color_hash({
            "FAILED" => error_color
          })
        end

        def job_colors
          return @job_colors if defined?(@job_colors)

          @job_colors = Hash.new(error_color)
          @job_colors.merge!({
            "0" => success_color,
            "BROKEN" => @pastel.dim
          })
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

        def build_header(build)
          io = StringIO.new

          started_at = Time.parse(build.started_at)
          finished_at = Time.parse(build.finished_at) if build.finished_at

          build_color = build_colors[build.state]

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

          io.string
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

        def call(args: {}, url_or_slug: nil)
          slug = determine_slug(url_or_slug)
          unless slug
            raise ArgumentError, "Unable to figure out slug to use"
          end

          result = query(BuildAnnotationsQuery, variables: {slug: slug})

          TTY::Pager.page do |page|
            build = result.data.build

            page.puts build_header(build)
            page.puts ""

            annotation_edges = build.annotations.edges
            annotations = annotation_edges.map { |edge| edge.node }

            # indent each annotation to separate it from the build status
            annotations.each_with_index do |annotation, index|
              style = annotation.style
              color = annotation_colors[style]

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

        option :glob, required: false, desc: "Glob of artifacts to list"
        option :download, type: :boolean, required: false, desc: "Should or should not download"

        BuildArtifactsQuery = Client.parse <<-GRAPHQL
          query($slug: ID!, $jobs_after: String) {
            build(slug: $slug) {
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

              jobs(first: 500, after: $jobs_after) {
                pageInfo {
                  endCursor
                  hasNextPage
                }
                edges {
                  node {
                    __typename
                    ... on JobTypeWait {
                      uuid
                      label
                    }
                    ... on JobTypeTrigger {
                      uuid
                      label
                    }

                    ... on JobTypeCommand {
                      uuid
                      label

                      url
                      exitStatus

                      parallelGroupIndex
                      parallelGroupTotal

                      artifacts(first: 500) {
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

        def call(args: {}, url_or_slug: nil, **options)
          slug = determine_slug(url_or_slug)
          unless slug
            raise ArgumentError, "Unable to figure out slug to use"
          end

          glob = options[:glob]
          download = options[:download]

          jobs_after = nil
          has_next_page = true

          while has_next_page
            result = query(BuildArtifactsQuery, variables: {slug: slug, jobs_after: jobs_after})

            build = result.data.build
            # only show the first time
            if jobs_after.nil?
              puts build_header(build)
              puts ""
            end

            jobs_after = build.jobs.page_info.end_cursor
            has_next_page = build.jobs.page_info.has_next_page

            jobs = build.jobs.edges.map(&:node)
            jobs.each do |job|
              next unless job.respond_to?(:exit_status)

              artifacts = job.artifacts.edges.map(&:node).select { |artifact| glob_matches?(glob, artifact.path) }
              next unless artifacts.any?

              color = job_colors[job.exit_status]
              header = color.call(job.label)
              if job.parallel_group_index && job.parallel_group_total
                header = "#{header} (#{job.parallel_group_index + 1}/#{job.parallel_group_total})"
              end

              puts header

              artifacts.each do |artifact|
                if download
                  puts "  - #{artifact.path} (downloading to tmp/bk/[filename])"
                  download_artifact(artifact)
                else
                  puts "  - #{artifact.path}"
                end
              end
            end
          end
        end

        def glob_matches?(glob, path)
          if glob
            File.fnmatch?(glob, path, File::FNM_PATHNAME)
          else
            true
          end
        end

        def download_artifact(artifact)
          download_url = artifact.to_h["downloadURL"]
          redirected_response_from_aws = Net::HTTP.get_response(URI(download_url))
          artifact_response = Net::HTTP.get_response(URI(redirected_response_from_aws["location"]))
          path = Pathname.new("tmp/bk/#{artifact.path}")
          FileUtils.mkdir_p(path.dirname)
          path.write(artifact_response.body)
        end
      end

      register "annotations", Annotations
      register "artifacts", Artifacts
    end
  end
end

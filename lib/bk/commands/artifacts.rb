require 'parallel'
require 'ruby-progressbar'

module Bk
  module Commands
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
          result = query(BuildArtifactsQuery, variables: { slug: slug, jobs_after: jobs_after })

          build = result.data.build
          # only show the first time
          if jobs_after.nil?
            puts build_header(build)
            puts ""
          end

          jobs_after = build.jobs.page_info.end_cursor
          has_next_page = build.jobs.page_info.has_next_page

          jobs = build.jobs.edges.map(&:node)
          bar = ProgressBar.create(total: jobs.count, throttle_rate: 1, format: '%a %t [%c/%C BK jobs]: %B %j%%, %E')

          Parallel.each(jobs, in_threads: 8) do |job|
            bar.increment
            next unless job.respond_to?(:exit_status)

            artifacts = job.artifacts.edges.map(&:node).select { |artifact| glob_matches?(glob, artifact.path) }
            next unless artifacts.any?

            color = job_colors[job.exit_status]
            header = color.call(job.label)

            artifacts.each do |artifact|
              if download
                download_artifact(artifact, header, bar)
              else
                bar.log "#{header}: #{artifact.path}"
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

      def download_artifact(artifact, header, bar)
        path = Pathname.new("tmp/bk/#{artifact.path}")
        if path.exist?
          bar.log "#{header}: #{path} already exists, skipping"
          return
        end

        sleep_duration = 1
        begin
          bar.log "#{header}: Downloading artifact to tmp/bk/#{artifact.path}"
          download_url = artifact.to_h["downloadURL"]
          redirected_response_from_aws = Net::HTTP.get_response(URI(download_url))
          artifact_response = Net::HTTP.get_response(URI(redirected_response_from_aws["location"]))
          FileUtils.mkdir_p(path.dirname)
          path.write(artifact_response.body)
        rescue => ex
          return if sleep_duration > 300
          bar.log "Retrying after #{sleep_duration} seconds (encountered error: #{ex})"
          sleep sleep_duration
          sleep_duration *= 2
          retry
        end
      end
    end
  end
end

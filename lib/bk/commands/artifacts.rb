require 'parallel'

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
          Parallel.each(jobs) do |job|
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
                puts "  - Downloading artifact to tmp/bk/#{artifact.path}"
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
        path = Pathname.new("tmp/bk/#{artifact.path}")
        if path.exist?
          puts "#{path} already exists, skipping"
          return
        end

        sleep_duration = 1
        begin
          download_url = artifact.to_h["downloadURL"]
          redirected_response_from_aws = Net::HTTP.get_response(URI(download_url))
          artifact_response = Net::HTTP.get_response(URI(redirected_response_from_aws["location"]))
          FileUtils.mkdir_p(path.dirname)
          path.write(artifact_response.body)
        rescue
          return if sleep_duration > 300
          puts "Retry"
          sleep sleep_duration
          sleep_duration *= 2
          retry
        end
      end
    end
  end
end

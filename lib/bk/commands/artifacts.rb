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

              jobs(first: 50, after: $jobs_after) {
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

      DownloadableArtifact = Struct.new(:artifact, :job_exit_status, :job_label, :parallel_notation) do
        include Format
        include Color

        def path
          artifact.path
        end

        def download_url
          artifact.to_h["downloadURL"]
        end

        def header
          color = job_colors[job_exit_status]
          base_header = color.call(job_label)
          if parallel_notation == ""
            base_header
          else
            "#{base_header} #{parallel_notation}"
          end
        end
      end

      def call(args: {}, url_or_slug: nil, **options)
        slug = determine_build_slug(url_or_slug)
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
          # https://github.com/jfelchner/ruby-progressbar/wiki/Formatting
          # %a – elapsed time
          # %t – Title
          # %c – Number of items currently completed
          # %C – Total number of items to be completed
          # %B – The full progress bar including 'incomplete' space
          # %j – Percentage complete represented as a whole number, right justified to 3 spaces
          # %E – Estimated time (will fall back to ETA: > 4 Days when it exceeds 99:00:00)
          bar = ProgressBar.create(total: jobs.count, throttle_rate: 1, format: "%a %t [%c/%C BK jobs]: %B %j%%, %E")
          bar.log "Fetching artifact paths for #{jobs.count} jobs..."
          all_matching_artifacts = []

          Parallel.each(jobs, in_threads: 8) do |job|
            bar.increment
            next unless job.respond_to?(:exit_status)

            artifacts = job.artifacts.edges.map(&:node).select { |artifact| glob_matches?(glob, artifact.path) }
            next unless artifacts.any?

            artifacts.each do |artifact|
              parallel_notation = if job.parallel_group_index && job.parallel_group_total
                "(#{job.parallel_group_index + 1}/#{job.parallel_group_total})"
              else
                ""
              end

              all_matching_artifacts << DownloadableArtifact.new(
                artifact,
                job.exit_status,
                job.label,
                parallel_notation
              )
            end
          end

          if download
            bar.log "Now downloading #{all_matching_artifacts.count} artifacts!"
            bar = ProgressBar.create(total: all_matching_artifacts.count, throttle_rate: 1, format: "%a %t [%c/%C artifacts]: %B %j%%, %E")
            Parallel.each(all_matching_artifacts, in_threads: 8) do |artifact|
              download_artifact(artifact, bar)
              bar.increment
            end
          else
            all_matching_artifacts.each do |artifact|
              bar.log "#{artifact.header}: #{artifact.path}"
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

      def download_artifact(artifact, bar)
        path = Pathname.new("tmp/bk/#{artifact.path}")
        if path.exist?
          bar.log "#{artifact.header}: #{path} already exists, skipping"
          return
        end

        sleep_duration = 1
        begin
          bar.log "#{artifact.header}: Downloading artifact to tmp/bk/#{artifact.path}"
          redirected_response_from_aws = Net::HTTP.get_response(URI(artifact.download_url))
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

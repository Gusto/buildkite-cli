module Bk
  module Commands
    class Logs < Base
      desc "Show Logs for a Job"
      argument :url_or_org, type: :string, required: false, desc: "Buildkite organization or Job URL"
      argument :pipeline, type: :string, required: false, desc: "Buildkite pipeline"
      argument :build_number, type: :string, required: false, desc: "Buildkite build number"
      argument :job_id, type: :string, required: false, desc: "Buildkite job_id"

      def call(args: {}, url_or_org: nil, pipeline: nil, build_number: nil, job_id: nil, **options)
        attributes = if url_or_org.start_with?("https:")
          parse_job_attributes_from_url(url_or_org)
        else
          {
            org: url_or_org,
            pipeline: pipeline,
            build_number: build_number,
            job_id: job_id
          }
        end

        response = Bk.buildkit.job_log(attributes[:org], attributes[:pipeline], attributes[:build_number], attributes[:job_id])
        puts response[:content]
      end
    end
  end
end

module Bk
  module Commands
    extend Dry::CLI::Registry

    class Base < Dry::CLI::Command
      include Color
      include Format

      attr_reader :spinner

      def initialize(buildkite_api_token: nil)
        @spinner = TTY::Spinner.new("Talking to Buildkite API... :spinner", clear: true, format: :dots)
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
    end

    register "annotations", Annotations
    register "artifacts", Artifacts
  end
end

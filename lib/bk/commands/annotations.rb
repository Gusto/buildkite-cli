module Bk
  module Commands
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
        slug = determine_build_slug(url_or_slug)
        unless slug
          raise ArgumentError, "Unable to figure out slug to use"
        end

        result = query(BuildAnnotationsQuery, variables: {slug: slug})

        build = result.data.build

        $stdout.puts build_header(build)
        $stdout.puts ""

        annotation_edges = build.annotations.edges
        annotations = annotation_edges.map { |edge| edge.node }

        format = AnnotationFormatter::Markdown.new
        # indent each annotation to separate it from the build status
        annotations.each_with_index do |annotation, index|
          $stdout.puts format.call(annotation)
          # horizontal separator between each
          unless index == annotations.length - 1
            $stdout.puts ""
            $stdout.puts "  #{HORIZONTAL_PIPE * (TTY::Screen.width - 4)}  "
            $stdout.puts ""
          end
        end
      end
    end
  end
end

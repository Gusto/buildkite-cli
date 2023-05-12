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
  end
end

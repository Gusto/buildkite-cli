module Bk
  module AnnotationFormatter
    class Markdown
      include Color
      include Format

      def call(annotation)
        io = StringIO.new

        style = annotation.style
        color = annotation_colors[style]

        context = annotation.context
        io.puts "  #{color.call("#{vertical_pipe}#{context}")}"
        io.puts "  #{color.call(vertical_pipe)}"

        body = annotation.body.text
        output = TTY::Markdown.parse(body)
        output.each_line do |line|
          io.puts "  #{color.call(vertical_pipe)}  #{line}"
        end

        io.string
      end
    end
  end
end

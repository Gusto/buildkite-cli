module TTYMarkdownConverterExtension
  def convert_html_element(el, opts)
    if el.value == "span"
      color = color_from_span_class(el.attr["class"])
      return super unless color

      pastel.send(color, inner(el, opts))
    else
      super
    end
  end

  def color_from_span_class(css_class)
    match = css_class.match(/^term-(?:[fb]g)(\d+)$/)
    return unless match

    color_code = Integer(match[2])

    Pastel::ANSI::ATTRIBUTES.key(color_code)
  end

  def pastel
    @pastel ||= Pastel.new
  end
end

class TTY::Markdown::Converter
  prepend TTYMarkdownConverterExtension
end

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

        output = TTY::Markdown.parse(annotation.body.text)

        output.each_line do |line|
          io.puts "  #{color.call(vertical_pipe)}  #{line}"
        end

        io.string
      end
    end
  end
end

module Bk
  module Color
    def success_color
      @success_color ||= pastel.green.detach
    end

    def error_color
      @error_color ||= pastel.red.detach
    end

    def warning_color
      @warning_color ||= pastel.yellow.detach
    end

    def info_color
      @info_color ||= pastel.blue.detach
    end

    def default_color
      @default_color ||= pastel.white.detach
    end

    def colorize(text, color)
      is_tty? ? color.call(text) : text
    end

    def create_color_hash(mappings = {})
      hash = Hash.new(default_color)
      hash.merge!(mappings)
    end
  end
end

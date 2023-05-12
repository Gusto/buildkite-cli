module Bk
  module Format
    VERTICAL_PIPE = "⏐"
    HORIZONTAL_PIPE = "⎯"

    def pastel
      @pastel ||= Pastel.new
    end

    def vertical_pipe
      is_tty? ? "#{VERTICAL_PIPE} " : ""
    end

    def is_tty?
      $stdout.tty?
    end

    def build_header(build)
      io = StringIO.new

      started_at = Time.parse(build.started_at)
      finished_at = Time.parse(build.finished_at) if build.finished_at

      build_color = build_colors[build.state]

      build_url = pastel.dim("» #{build.url}")
      # TODO handle multi-line message better
      io.puts "#{build_color.call(vertical_pipe)}#{pastel.bold(build.message)} #{build_url}"
      io.puts build_color.call(vertical_pipe)

      state = if build.state == "RUNNING" || build.state == "FAILING"
        duration = Time.now - started_at
        minutes = (duration / 60).to_i
        seconds = (duration % 60).to_i
        "running for #{minutes}m #{seconds}s"
      elsif finished_at
        duration = finished_at - started_at
        "#{build.state.downcase.capitalize} in #{duration}s"
      end

      parts = [
        "Build ##{build.number}",
        build.branch,
        build_color.call(state)
      ].join(pastel.dim("  |  "))
      io.puts "#{build_color.call(vertical_pipe)}#{parts}"

      io.string
    end

    def annotation_colors
      return @annotation_colors if defined?(@annotation_colors)

      @annotation_colors = create_color_hash({
        "SUCCESS" => success_color,
        "ERROR" => error_color,
        "WARNING" => warning_color,
        "INFO" => info_color
      })
    end

    def build_colors
      return @build_colors if defined?(@build_colors)
      @build_colors = create_color_hash({
        "FAILED" => error_color
      })
    end

    def job_colors
      return @job_colors if defined?(@job_colors)

      @job_colors = Hash.new(error_color)
      @job_colors.merge!({
        "0" => success_color,
        "BROKEN" => @pastel.dim
      })
    end
  end
end

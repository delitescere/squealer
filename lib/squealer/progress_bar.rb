module Squealer
  class ProgressBar

    def initialize(total)
      @total = total
      @ticks = 0

      @progress_bar_width = 50
      @count_width = @total.to_s.size
    end

    def tick
      @start_time ||= Time.new
      @ticks += 1
      @end_time = Time.new if done?
    end

    def emit
      format = "\r[%-#{progress_bar_width}s] %#{count_width}i/%i (%i%%)"
      console.print format % [progress_markers, ticks, total, percentage]
      console.puts if done?
    end

    private

    def done?
      ticks == total
    end

    def ticks
      @ticks
    end

    def total
      @total
    end

    def percentage
      ((ticks.to_f / total) * 100).floor
    end

    def progress_markers
      "=" * ((ticks.to_f / total) * progress_bar_width).floor
    end

    def console
      $stderr
    end

    def progress_bar_width
      @progress_bar_width
    end

    def count_width
      @count_width
    end

  end
end

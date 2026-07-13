require_relative '../constants.rb'

module AlgoHelpers
  include Constants

  # global switch for the algorithms' debug printouts (grids, per-move logs)
  @verbose = false
  # pause between rendered moves so a verbose game is watchable
  @watch_delay = 0.0

  class << self
    attr_accessor :verbose, :watch_delay

    def watch_pause
      sleep(@watch_delay) if @watch_delay.positive?
    end
  end

  def valid_coordinates?(row, column)
    row.between?(0, Constants::GRID_SIZE - 1) && column.between?(0, Constants::GRID_SIZE - 1)
  end
end

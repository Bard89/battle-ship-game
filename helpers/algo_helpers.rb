require_relative '../constants.rb'

module AlgoHelpers
  include Constants

  # global switch for the algorithms' debug printouts (grids, per-move logs)
  @verbose = false

  class << self
    attr_accessor :verbose
  end

  def valid_coordinates?(row, column)
    row.between?(0, Constants::GRID_SIZE - 1) && column.between?(0, Constants::GRID_SIZE - 1)
  end
end

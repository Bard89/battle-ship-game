require_relative '../constants.rb'

module AlgoHelpers
  include Constants

  module_function

  def valid_coordinates?(row, column)
    row.between?(0, Constants::GRID_SIZE - 1) && column.between?(0, Constants::GRID_SIZE - 1)
  end
end

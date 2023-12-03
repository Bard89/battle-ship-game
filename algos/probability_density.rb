require_relative '../map_generator.rb'
require_relative '../helpers.rb'
require_relative '../constants.rb'
require_relative '../battleship_api_mock.rb'

require 'byebug'

module ProbabilityDensity
  include Helpers
  include Constants

  module_function

  def probability_density(api)
    probability_grid = initialize_probability_grid
    until api.finished?
      row, col = highest_probability_cell(probability_grid)
      response = api.fire(row, col)
      update_probability_grid(probability_grid, row, col, response["result"])
      puts
      api.print_probability_grid(probability_grid)
      puts "move count: #{response["moveCount"]}"
    end
  end

  def initialize_probability_grid
    Array.new(Constants::GRID_SIZE) { Array.new(Constants::GRID_SIZE, 1.0 / (Constants::GRID_SIZE * Constants::GRID_SIZE)) }
  end

  def highest_probability_cell(probability_grid)
    max_prob = probability_grid.flatten.max
    probability_grid.each_with_index do |row, r_index|
      row.each_with_index do |prob, c_index|
        return [r_index, c_index] if prob == max_prob
      end
    end
  end

  def update_probability_grid(grid, row, col, hit)
    if hit
      # Increase probability of neighboring cells
      adjust_probabilities(grid, row, col, :increase)
    else
      # Decrease or set to zero for this cell
      grid[row][col] = 0
      adjust_probabilities(grid, row, col, :decrease)
    end
  end

  def adjust_probabilities(grid, row, col, adjustment)
    adjustment_factor = adjustment == :increase ? 1.1 : 0.9
    # Iterate through the surrounding cells
    (-1..1).each do |row_offset|
      (-1..1).each do |col_offset|
        new_row, new_col = row + row_offset, col + col_offset
        if valid_coordinates?(new_row, new_col)
          # Adjust the probability of the cell
          grid[new_row][new_col] *= adjustment_factor
        end
      end
    end

    normalize_probabilities(grid) if adjustment == :decrease
  end

  def valid_coordinates?(row, column)
    row.between?(0, Constants::GRID_SIZE - 1) && column.between?(0, Constants::GRID_SIZE - 1)
  end

  def normalize_probabilities(grid)
    total_probability = grid.flatten.sum
    grid.each_with_index do |row, r_index|
      row.each_with_index do |prob, c_index|
        grid[r_index][c_index] /= total_probability
      end
    end
  end
end

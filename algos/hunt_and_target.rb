# currently not being used, but it represents one of the possible strategies
# not the most efficient strategy, but easier to understand and implement compared to the probability density strategy
require_relative '../map_generator.rb'
require_relative '../helpers/print_helpers.rb'
require_relative '../helpers/algo_helpers.rb'
require_relative '../constants.rb'

require 'byebug'

module HuntAndTarget
  extend PrintHelpers
  extend AlgoHelpers
  include Constants

  module_function

  def hunt_and_target(api)
    # what we know so far, built purely from API responses: '*' unknown, 'X' hit, '.' miss
    known_grid = Array.new(Constants::GRID_SIZE) { Array.new(Constants::GRID_SIZE, '*') }
    target_mode = false
    last_hit = nil

    loop do
      row, col = if target_mode && last_hit
                   find_next_target(known_grid, last_hit)
                 else
                   find_random_target(known_grid)
                 end

      response = api.fire(row, col)
      known_grid = response["grid"].chars.each_slice(Constants::GRID_SIZE).to_a

      if response["cell"] == 'X'
        target_mode = true
        last_hit = [row, col]
        puts "Hit at #{row}, #{col}" if AlgoHelpers.verbose
      else
        target_mode = false if target_mode && !adjacent_cells_hit?(known_grid, last_hit)
        puts "Miss at #{row}, #{col}" if AlgoHelpers.verbose
      end

      if response["finished"]
        if AlgoHelpers.verbose
          puts "Game over in #{response["moveCount"]} moves"
          print_grid(response["grid"])
        end
        break
      end
    end
  end

  def find_next_target(grid, last_hit)
    row, col = last_hit
    adjacent_cells = [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]]

    target = adjacent_cells.shuffle.find { |r, c| valid_target?(grid, r, c) }
    target || find_random_target(grid)
  end

  def find_random_target(grid)
    loop do
      row = rand(Constants::GRID_SIZE)
      col = rand(Constants::GRID_SIZE)
      return [row, col] if valid_target?(grid, row, col)
    end
  end

  def adjacent_cells_hit?(grid, cell)
    row, col = cell
    [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]].any? do |r, c|
      grid[r][c] == 'X' if r.between?(0, Constants::GRID_SIZE - 1) && c.between?(0, Constants::GRID_SIZE - 1)
    end
  end

  def valid_target?(grid, row, col)
    row.between?(0, Constants::GRID_SIZE - 1) && col.between?(0, Constants::GRID_SIZE - 1) && grid[row][col] == '*'
  end
end

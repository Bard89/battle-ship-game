require_relative 'map_generator.rb'
require_relative 'helpers.rb'
require_relative 'constants.rb'
require_relative 'battleship_api_mock.rb'

require 'byebug'

module Algos
  include Helpers
  include Constants

  module_function

  def brute_force(api)
    (0..(Constants::GRID_SIZE - 1)).each do |row|
      (0..(Constants::GRID_SIZE - 1)).each do |column|
        response = api.fire(row, column)
        puts "Response: #{response}"

        if response["result"]
          puts "Hit at #{row}, #{column}"
          api.print_grid(response["grid"])
        else
          puts "Miss at #{row}, #{column}"
        end

        if response["finished"]
          puts "Game over in #{response["moveCount"]} moves"
          api.print_grid(response["grid"])
          return
        end
      end
    end
  end

  def hunt_and_target(api)
    target_mode = false
    last_hit = nil

    loop do
      row, col = if target_mode && last_hit
                   find_next_target(api.grid, last_hit)
                 else
                   find_random_target(api.grid)
                 end

      response = api.fire(row, col)

      if response["result"]
        target_mode = true
        last_hit = [row, col]
        puts "Hit at #{row}, #{col}"
      else
        target_mode = false if target_mode && !adjacent_cells_hit?(api.grid, last_hit)
        puts "Miss at #{row}, #{col}"
      end

      if response["finished"]
        puts "Game over in #{response["moveCount"]} moves"
        api.print_grid(response["grid"])
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
    row.between?(0, Constants::GRID_SIZE - 1) && col.between?(0, Constants::GRID_SIZE - 1) && (grid[row][col] == '*' || grid[row][col] == 'S')
  end
end

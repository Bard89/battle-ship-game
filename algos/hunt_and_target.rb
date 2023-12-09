require_relative '../map_generator.rb'
require_relative '../helpers.rb'
require_relative '../constants.rb'
require_relative '../battleship_api_mock.rb'

require 'byebug'

module HuntAndTarget
  include Helpers
  include Constants

  module_function

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

# def hunt_and_target(api)
#   last_hit = nil
#
#   until api.finished?
#     if last_hit
#       # Target phase
#       last_hit = target_phase(api, last_hit)
#     else
#       # Hunt phase
#       last_hit = hunt_phase(api)
#     end
#   end
# end
#
# def hunt_phase(api)
#   parity_coordinates = initialize_parity_coordinates
#   while true
#     row, col = random_parity_coordinates(parity_coordinates)
#     response = api.fire(row, col)
#     return [row, col] if response["result"] # Return hit coordinates
#     break if response["finished"]
#
#     # Remove the coordinate from the list to avoid firing at the same place
#     parity_coordinates.delete([row, col])
#   end
#   nil # Return nil if no hit or game is finished
# end
#
# def target_phase(api, hit_coordinates)
#   adjacent_cells = get_adjacent_cells(hit_coordinates)
#
#   adjacent_cells.each do |row, col|
#     response = api.fire(row, col)
#     return [row, col] if response["result"] # Return new hit coordinates
#     return nil if response["finished"]
#   end
#
#   nil # Return nil if no further hits or game is finished
# end
#
# def random_parity_coordinates(parity_coordinates)
#   parity_coordinates.sample
# end
#
#
# def get_adjacent_cells(coordinates)
#   row, col = coordinates
#   [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]].select do |r, c|
#     r.between?(0, Constants::GRID_SIZE - 1) && c.between?(0, Constants::GRID_SIZE - 1)
#   end
# end
#
# def initialize_parity_coordinates
#   parity_coordinates = []
#   (0...Constants::GRID_SIZE).each do |row|
#     (0...Constants::GRID_SIZE).each do |col|
#       parity_coordinates << [row, col] if (row + col).even?
#     end
#   end
#   parity_coordinates
# end

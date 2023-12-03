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

  def probability_density(api)
    probability_grid = initialize_probability_grid
    until api.finished?
      row, col = highest_probability_cell(probability_grid)
      response = api.fire(row, col)
      update_probability_grid(probability_grid, row, col, response["result"])
      # Print statements can be added here for debugging
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

    # Normalize probabilities if needed
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

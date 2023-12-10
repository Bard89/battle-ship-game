require_relative '../map_generator.rb'
require_relative '../constants.rb'
require_relative '../battleship_api_mock.rb'
require 'byebug'

module BattleshipSolver
  include Helpers
  include Constants

  module_function

  def probability_density(api)
    probability_grid = initialize_probability_grid
    update_grid_with_irregular_ship_probabilities(probability_grid) # Initialize probabilities for irregular ship

    api.print_probability_grid(probability_grid)
    byebug

    until api.finished? # until the game is over
      if api.avengerAvailable # if the biggest ship is sunk, use the avenger
        target_row, target_col = find_highest_probability_target(probability_grid)
      else
        target_row, target_col = target_irregular_ship(probability_grid)
      end

      puts
      puts "Targeting row #{target_row}, col #{target_col}"

      result = api.fire(target_row, target_col)
      hit = result['result']
      update_probability(probability_grid, target_row, target_col, hit)
    end
  end

  # Initialize the probability grid for the game with 0s, will be updated according to the ship shapes
  # first for the irregular ship and then for the regular ships
  def initialize_probability_grid
    Array.new(Constants::GRID_SIZE) { Array.new(Constants::GRID_SIZE, 0.0) }
  end

  # Updates the probability grid with probabilities of the irregular ship's placement
  def update_grid_with_irregular_ship_probabilities(grid)
    Constants::GRID_SIZE.times do |row|
      Constants::GRID_SIZE.times do |col|
        increase_probability_for_irregular_ship(grid, row, col, 0.01)
      end
    end
  end

  # Increase probability for cells where the irregular ship can be placed
  def increase_probability_for_irregular_ship(grid, row, col, increment)
    update_probability_for_horizontal_ship_position(grid, row, col, IRREGULAR_SHIP_HORIZONTAL, increment) if can_whole_horizontal_ship_be_here?(row, col)
    update_probability_for_vertical_ship_position(grid, row, col, IRREGULAR_SHIP_VERTICAL, increment) if can_whole_vertical_ship_be_here?(row, col)
  end

  def can_whole_horizontal_ship_be_here?(row, col)
    half_length_of_the_ship =  IRREGULAR_SHIP_HORIZONTAL[0].length / 2 # columns
    half_width_of_the_ship = IRREGULAR_SHIP_HORIZONTAL.length / 2 # rows

    return false if col - half_length_of_the_ship < 0
    return false if col + half_length_of_the_ship > Constants::GRID_SIZE - 1
    return false if row - half_width_of_the_ship < 0
    return false if row + half_width_of_the_ship > Constants::GRID_SIZE - 1

    true
  end

  def can_whole_vertical_ship_be_here?(row, col)
    half_length_of_the_ship =  IRREGULAR_SHIP_VERTICAL[0].length / 2 # columns
    half_width_of_the_ship = IRREGULAR_SHIP_VERTICAL.length / 2 # rows

    return false if col - half_length_of_the_ship < 0
    return false if col + half_length_of_the_ship > Constants::GRID_SIZE - 1
    return false if row - half_width_of_the_ship < 0
    return false if row + half_width_of_the_ship > Constants::GRID_SIZE - 1

    true
  end

  def update_probability_for_horizontal_ship_position(grid, row, col, ship_shape, increment)
    ship_shape.each_with_index do |ship_row, r_offset|
      ship_row.each_with_index do |cell, c_offset|
        next unless cell == 'I' # Only consider the 'I' cells of the ship

        grid_row = row + r_offset - 1
        grid_col = col + c_offset - 2

        grid[grid_row][grid_col] += increment
      end
    end
  end

  def update_probability_for_vertical_ship_position(grid, row, col, ship_shape, increment)
    ship_shape.each_with_index do |ship_row, r_offset|
      ship_row.each_with_index do |cell, c_offset|
        next unless cell == 'I' # Only consider the 'I' cells of the ship

        grid_row = row + r_offset - 2
        grid_col = col + c_offset - 1

        grid[grid_row][grid_col] += increment
      end
    end
  end

  # Update the probability grid based on the result of each shot
  def update_probability(probability_grid, row, col, hit)
    action = hit ? :increase : :decrease

    update_adjacent_cells(probability_grid, row, col, action)
    normalize_probabilities(probability_grid)
  end

  # Target the irregular ship based on the probability grid
  def target_irregular_ship(probability_grid)
    highest_probability = 0
    target_position = [0, 0]

    [IRREGULAR_SHIP_HORIZONTAL, IRREGULAR_SHIP_VERTICAL].each do |ship_shape|
      Constants::GRID_SIZE.times do |row|
        Constants::GRID_SIZE.times do |col|
          # next unless can_place_whole_irregular_ship?(row, col, ship_shape)
          next unless can_whole_ship_be_here?(row, col)

          # byebug
          # puts "row: #{row}, col: #{col}"
          # byebug if can_irregular_ship_be_here?(row, col)

          probability_score = calculate_probability_score(probability_grid, row, col, ship_shape)
          if probability_score > highest_probability
            highest_probability = probability_score
            target_position = [row, col]
          end
        end
      end
    end

    target_position
  end

  def update_adjacent_cells(probability_grid, row, col, action)
    (-1..1).each do |row_offset|
      (-1..1).each do |col_offset|
        next unless valid_coordinates?(row + row_offset, col + col_offset)

        case action
        when :increase
          probability_grid[row + row_offset][col + col_offset] += 0.1 # Adjust this value as needed
        when :decrease
          probability_grid[row + row_offset][col + col_offset] -= 0.1 # Adjust this value as needed
        end
      end
    end
  end

  def normalize_probabilities(probability_grid)
    total = probability_grid.flatten.sum
    probability_grid.map! { |row| row.map { |prob| prob / total } }
  end

  def calculate_probability_score(probability_grid, row, col, ship_shape)
    score = 0

    ship_shape.each_with_index do |ship_row, r|
      ship_row.each_with_index do |cell, c|
        next unless cell == 'I' # Only consider the 'I' cells for the irregular ship

        score += probability_grid[row + r][col + c] if valid_coordinates?(row + r, col + c)
      end
    end

    score
  end

  def find_highest_probability_target(probability_grid)
    max_prob = probability_grid.flatten.max
    probability_grid.each_with_index do |row, r_idx|
      col_idx = row.index(max_prob)
      return [r_idx, col_idx] if col_idx
    end
  end












  def valid_coordinates?(row, column)
    row.between?(0, Constants::GRID_SIZE - 1) && column.between?(0, Constants::GRID_SIZE - 1)
  end
end

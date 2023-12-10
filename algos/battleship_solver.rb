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
    game_over = false

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

  # Initialize the probability grid for the game
  def initialize_probability_grid
    Array.new(Constants::GRID_SIZE) { Array.new(Constants::GRID_SIZE, 1.0 / (Constants::GRID_SIZE * Constants::GRID_SIZE)) }
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
          byebug
          next unless can_irregular_ship_be_here?(row, col)

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

  # def can_place_whole_irregular_ship?(row, col, ship_shape)
  #   ship_shape.each_with_index do |ship_row, r|
  #     ship_row.each_with_index do |cell, c|
  #       byebug
  #       next unless cell == 'I' # Only consider the 'I' cells
  #
  #       return false unless valid_coordinates?(row + r, col + c)
  #     end
  #   end
  #
  #   true
  # end

  def can_irregular_ship_be_here?(row, col)#, grid)
    ship_shape = [
      [nil, 'I', nil, 'I', nil],
      ['I', 'I', 'I', 'I', 'I'],
      [nil, 'I', nil, 'I', nil],
    ]

    ship_shape.each_with_index do |ship_row, r|
      ship_row.each_with_index do |cell, c|
        next unless cell == 'I' # Only consider the 'I' cells of the ship

        # Calculate the actual position on the grid
        grid_row = row + r - 1 # Offset by 1 to center the ship shape on the specified position
        grid_col = col + c - 1 # Offset by 1 to center the ship shape on the specified position

        # Check if the 'I' cell of the ship can be placed on the grid
        unless valid_coordinates?(grid_row, grid_col)# && grid[grid_row][grid_col] == '*'
          return false # 'I' cell is out of grid boundaries or overlaps with an existing ship
        end
      end
    end

    true # All 'I' cells can be placed
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

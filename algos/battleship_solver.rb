require_relative '../map_generator.rb'
require_relative '../constants.rb'
require_relative '../battleship_api_mock.rb'
require_relative 'solver_helpers.rb'
require 'byebug'

module BattleshipSolver
  include Helpers
  include Constants
  include SolverHelpers

  module_function

  def probability_density(api)
    probability_grid = initialize_probability_grid
    # update_grid_with_irregular_ship_probabilities(probability_grid) # Initialize probabilities for irregular ship
    update_grid_with_regular_ship_probabilities(probability_grid) # Initialize probabilities for regular ships

    api.print_probability_grid(probability_grid)
    byebug
    targeted_cells = Set.new

    # until api.finished? # until the game is over

    # just to optimize the game, to update the probabilities right
    until api.avengerAvailable
      # if api.avengerAvailable # if the biggest ship is sunk, use the avenger
      #   target_row, target_col = find_highest_probability_target(probability_grid)
      # else
        target_row, target_col = target_irregular_ship(probability_grid, targeted_cells)
      # end

        if targeted_cells.include?([target_row, target_col])
          raise "Already targeted cell #{target_row}, #{target_col}"
        end

        puts
        puts "Targeting row #{target_row}, col #{target_col}"
        targeted_cells.add([target_row, target_col])

        result = api.fire(target_row, target_col)
        update_probability(probability_grid, target_row, target_col, result['result'])

        api.print_probability_grid(probability_grid)
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
        [:horizontal, :vertical].each do |orientation|
          ship_shape = orientation == :horizontal ? IRREGULAR_SHIP_HORIZONTAL : IRREGULAR_SHIP_VERTICAL

          if can_whole_odd_ship_be_here?(row, col, ship_shape)
            # Increase probability for cells where the irregular ship can be placed
            update_probability_for_irregular_ship_position(grid, row, col, ship_shape, Constants::PROBABILITY_INCREMENT, orientation)
          end
        end
      end
    end
  end

  #updates the probability grid with probabilities of the regular ships' placement
  def update_grid_with_regular_ship_probabilities(grid)
    Constants::REGULAR_SHIP_SHAPES.each do |ship_shape|
      Constants::GRID_SIZE.times do |row|
        Constants::GRID_SIZE.times do |col|
          [:horizontal, :vertical].each do |orientation|
            ship_shape = orientation == :horizontal ? ship_shape : ship_shape.transpose

            if can_whole_even_ship_be_here?(row, col, ship_shape)
              # Increase probability for cells where the regular ship can be placed
              update_probability_for_regular_ship_position(grid, row, col, ship_shape, Constants::PROBABILITY_INCREMENT, orientation)
            end
          end
        end
      end
    end
  end

  def can_whole_odd_ship_be_here?(row, col, ship_shape)
    half_length_of_the_ship =  ship_shape[0].length / 2 # columns
    half_width_of_the_ship = ship_shape.length / 2 # rows

    return false if col - half_length_of_the_ship < 0
    return false if col + half_length_of_the_ship > Constants::GRID_SIZE - 1
    return false if row - half_width_of_the_ship < 0
    return false if row + half_width_of_the_ship > Constants::GRID_SIZE - 1

    true
  end

  def can_whole_even_ship_be_here?(row, col, ship_shape)
    length_of_the_ship = ship_shape[0].length
    width_of_the_ship = ship_shape.length

    # The center for an even length ship is between the two middle cells
    # For a ship of length 4, the "center" would be between cells 2 and 3
    center_offset_length = (length_of_the_ship.even? ? (length_of_the_ship / 2) - 1 : length_of_the_ship / 2)
    center_offset_width = (width_of_the_ship.even? ? (width_of_the_ship / 2) - 1 : width_of_the_ship / 2)

    # Calculate bounds for even length ship placement
    left_bound = col - center_offset_length
    right_bound = col + length_of_the_ship - center_offset_length - 1
    upper_bound = row - center_offset_width
    lower_bound = row + width_of_the_ship - center_offset_width - 1

    # Check bounds
    return false if left_bound < 0 || right_bound >= Constants::GRID_SIZE
    return false if upper_bound < 0 || lower_bound >= Constants::GRID_SIZE
    true
  end


  def update_probability_for_irregular_ship_position(grid, row, col, ship_shape, increment, orientation)
    ship_shape.each_with_index do |ship_row, r_offset|
      ship_row.each_with_index do |cell, c_offset|
        next unless (cell == 'I' || cell == 'S') # Only consider the 'I' cells of the irregular ship or the 'S' cells of the regular ship

        if orientation == :horizontal
          grid_row = row + r_offset - 1 # Centering adjustment for horizontal
          grid_col = col + c_offset - 2 # Centering adjustment for horizontal
        elsif orientation == :vertical
          grid_row = row + r_offset - 2 # Centering adjustment for vertical
          grid_col = col + c_offset - 1 # Centering adjustment for vertical
        end

        grid[grid_row][grid_col] += increment
      end
    end
  end

  # this one doesn't work on 100 percent, creates these stripes on the probability grid, Which I;m not suere matters
  # The probability should probably be increasing toward the center
  # TODO fix if you have enough time
  def update_probability_for_regular_ship_position(grid, row, col, ship_shape, increment, orientation)
    ship_shape.each_with_index do |ship_row, r_offset|
      ship_row.each_with_index do |cell, c_offset|
        next unless cell == 'S' # Consider only the 'S' cells of the regular ship

        # Calculate grid positions based on orientation and offset
        if orientation == :horizontal
          grid_row = row + r_offset
          grid_col = col + c_offset - (ship_shape[0].length.even? ? (ship_shape[0].length / 2) - 1 : ship_shape[0].length / 2)
        else # orientation == :vertical
          grid_row = row + r_offset - (ship_shape.length.even? ? (ship_shape.length / 2) - 1 : ship_shape.length / 2)
          grid_col = col + c_offset
        end

        # Update the probability grid within bounds
        if grid_row.between?(0, Constants::GRID_SIZE - 1) && grid_col.between?(0, Constants::GRID_SIZE - 1)
          grid[grid_row][grid_col] += increment
        end
      end
    end
  end


  def update_probability(probability_grid, row, col, hit)
    action = hit ? :increase : :decrease
    update_adjacent_cells(probability_grid, row, col, action)

    # If it's a hit, also consider ship placement patterns
    update_based_on_ship_patterns(probability_grid, row, col) if hit
  end

def target_irregular_ship(probability_grid, targeted_cells)
  highest_probability = -Float::INFINITY
  target_position = [-1, -1]

  probability_grid.each_with_index do |row, r_idx|
    row.each_with_index do |prob, c_idx|
      cell_position = [r_idx, c_idx]

      if prob > highest_probability && !targeted_cells.include?(cell_position)
        highest_probability = prob
        target_position = cell_position
      end
    end
  end

  if target_position == [-1, -1]
    raise "No valid target found. All cells may have been targeted."
  end

  target_position
end


  def update_adjacent_cells(probability_grid, row, col, action)
    (-1..1).each do |row_offset|
      (-1..1).each do |col_offset|
        next unless valid_coordinates?(row + row_offset, col + col_offset)
        next if row_offset == 0 && col_offset == 0  # Skip the cell that was just targeted

        case action
        when :increase
          probability_grid[row + row_offset][col + col_offset] += 0.1
        when :decrease
          probability_grid[row + row_offset][col + col_offset] -= 0.1
        end
      end
    end
  end

  def update_based_on_ship_patterns(probability_grid, row, col)
    # Increase probability of cells in a line extending from the hit cell
    [-1, 1].each do |offset|
      probability_grid[row + offset][col] += 0.2 if valid_coordinates?(row + offset, col)
      probability_grid[row][col + offset] += 0.2 if valid_coordinates?(row, col + offset)
    end
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

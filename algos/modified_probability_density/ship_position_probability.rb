require_relative '../../constants.rb'

module ShipPositionProbability
  # Initialize the probability grid for the game with 0s, will be updated according to the ship shapes
  # first for the irregular ship and then for the regular ships
  def initialize_probability_grid
    Array.new(Constants::GRID_SIZE) { Array.new(Constants::GRID_SIZE, 0.0) }
  end
end

# Updates the probability grid with probabilities of the irregular ship's placement
def update_grid_with_irregular_ship_probabilities(grid)
  Constants::GRID_SIZE.times do |row|
    Constants::GRID_SIZE.times do |col|
      [:horizontal, :vertical].each do |orientation|
        ship_shape = orientation == :horizontal ? Constants::IRREGULAR_SHIP_HORIZONTAL : Constants::IRREGULAR_SHIP_VERTICAL

        if can_whole_odd_ship_be_here?(row, col, ship_shape)
          # Increase probability for cells where the irregular ship can be placed
          update_probability_for_irregular_ship_position(grid, row, col, ship_shape, Constants::SHIP_PROBABILITY_INCREMENT, orientation)
        end
      end
    end
  end
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

#updates the probability grid with probabilities of the regular ships' placement
def update_grid_with_regular_ship_probabilities(grid)
  Constants::REGULAR_SHIP_SHAPES.each do |ship_shape|
    Constants::GRID_SIZE.times do |row|
      Constants::GRID_SIZE.times do |col|
        [:horizontal, :vertical].each do |orientation|
          ship_shape = orientation == :horizontal ? ship_shape : ship_shape.transpose

          if can_whole_even_ship_be_here?(row, col, ship_shape)
            # Increase probability for cells where the regular ship can be placed
            update_probability_for_regular_ship_position(grid, row, col, ship_shape, Constants::SHIP_PROBABILITY_INCREMENT, orientation)
          end
        end
      end
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

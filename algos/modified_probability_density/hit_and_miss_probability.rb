require_relative '../../constants.rb'

module HitAndMissProbability
  def update_probability(probability_grid, row, col, hit)
    action = hit ? :increase : :decrease
    update_adjacent_cells(probability_grid, row, col, action)

    # If it's a hit, also consider ship placement patterns
    update_probabilities_after_miss(probability_grid, row, col, Constants::REGULAR_SHIP_SHAPES) unless hit
    update_based_on_ship_patterns(probability_grid, row, col) if hit
  end

  def update_adjacent_cells(probability_grid, row, col, action)
    (-1..1).each do |row_offset|
      (-1..1).each do |col_offset|
        next unless valid_coordinates?(row + row_offset, col + col_offset)
        next if row_offset == 0 && col_offset == 0  # Skip the cell that was just targeted

        case action
        when :increase
          probability_grid[row + row_offset][col + col_offset] += Constants::ADJACENT_CELL_PROBABILITY_INCREMENT
        when :decrease
          probability_grid[row + row_offset][col + col_offset] -= Constants::ADJACENT_CELL_PROBABILITY_DECREMENT
        end
      end
    end
  end
end

def update_probabilities_after_miss(grid, missed_row, missed_col, ship_shapes)
  ship_shapes.each do |ship_shape|
    Constants::GRID_SIZE.times do |row|
      Constants::GRID_SIZE.times do |col|
        [:horizontal, :vertical].each do |orientation|
          # Generate the ship placement based on the orientation
          ship_placement = orientation == :horizontal ? ship_shape : ship_shape.transpose

          # If the ship overlaps the missed cell, decrease the probabilities
          if overlaps_missed_cell?(ship_placement, row, col, missed_row, missed_col)
            decrease_probability_for_ship_placement(grid, row, col, ship_placement)
          end
        end
      end
    end
  end
end

def update_based_on_ship_patterns(probability_grid, row, col)
  # Increase probability of cells in a line extending from the hit cell
  [-1, 1].each do |offset|
    probability_grid[row + offset][col] += Constants::SHIP_PATTERN_PROBABILITY_INCREMENT if valid_coordinates?(row + offset, col)
    probability_grid[row][col + offset] += Constants::SHIP_PATTERN_PROBABILITY_INCREMENT if
      valid_coordinates?(row, col + offset)
  end
end

def decrease_probability_for_ship_placement(grid, row, col, ship_placement)
  ship_placement.each_with_index do |ship_row, r_offset|
    ship_row.each_with_index do |cell, c_offset|
      # Calculate the absolute position of the cell in the grid
      absolute_row = row + r_offset
      absolute_col = col + c_offset

      # Decrease the probability if the cell is within the grid boundaries
      if valid_coordinates?(absolute_row, absolute_col)
        grid[absolute_row][absolute_col] -= Constants::SHIP_PROBABILITY_DECREMENT
      end
    end
  end
end

require_relative '../../constants.rb'

module HitAndMissProbability
  def update_probability(probability_grid, row, col, hit)
    update_adjacent_cells(probability_grid, row, col, hit)
    update_probabilities_after_miss(probability_grid, row, col, Constants::REGULAR_SHIP_SHAPES) unless hit
    update_based_on_ship_patterns(probability_grid, row, col) if hit
  end

  def update_adjacent_cells(probability_grid, row, col, hit)
    action = hit ? :increase : :decrease

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

  def update_probabilities_after_miss(grid, missed_row, missed_col, ship_shapes)
    ship_shapes.each do |ship_shape|
      Constants::GRID_SIZE.times do |row|
        Constants::GRID_SIZE.times do |col|
          [:horizontal, :vertical].each do |orientation|
            ship_placement = orientation == :horizontal ? ship_shape : ship_shape.transpose

            decrease_probability_for_ship_placement(grid, row, col, ship_placement) if overlaps_missed_cell?(ship_placement, row, col, missed_row, missed_col)
          end
        end
      end
    end
  end

  def overlaps_missed_cell?(ship_placement, row, col, missed_row, missed_col)
    ship_placement.each_with_index do |ship_row, r_offset|
      ship_row.each_with_index do |cell, c_offset|
        offset_row = row + r_offset
        offset_col = col + c_offset

        return true if offset_row == missed_row && offset_col == missed_col
      end
    end
    false
  end

  def decrease_probability_for_ship_placement(grid, row, col, ship_placement)
    ship_placement.each_with_index do |ship_row, r_offset|
      ship_row.each_with_index do |_, c_offset|
        offset_row = row + r_offset
        offset_col = col + c_offset

        grid[offset_row][offset_col] -= Constants::SHIP_PLACEMENT_PROBABILITY_DECREMENT if valid_coordinates?(offset_row, offset_col)
      end
    end
  end

  def update_based_on_ship_patterns(probability_grid, row, col)
    # Increase probability of cells in a line extending from the hit cell
    [-1, 1].each do |offset|
      probability_grid[row + offset][col] += Constants::SHIP_PATTERN_PROBABILITY_INCREMENT if valid_coordinates?(row + offset, col)
      probability_grid[row][col + offset] += Constants::SHIP_PATTERN_PROBABILITY_INCREMENT if valid_coordinates?(row, col + offset)
    end
  end
end

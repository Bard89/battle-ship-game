require_relative '../../constants.rb'

module HitAndMissProbability
  def update_adjacent_cells(probability_grid, row, col, hit)
    (-1..1).each do |row_offset|
      (-1..1).each do |col_offset|
        next unless valid_coordinates?(row + row_offset, col + col_offset)
        next if row_offset == 0 && col_offset == 0  # Skip the cell that was just targeted

        increment = hit ? Constants::ADJACENT_CELL_PROBABILITY_INCREMENT : -Constants::ADJACENT_CELL_PROBABILITY_DECREMENT
        probability_grid[row + row_offset][col + col_offset] += increment
      end
    end
  end

  def update_hit_or_miss_probability(probability_grid, row, col, hit)
    if hit
      update_based_on_ship_pattern(probability_grid, row, col)
    else
      update_after_miss(probability_grid, row, col, Constants::REGULAR_SHIP_SHAPES)
    end
  end

  def update_after_miss(grid, missed_row, missed_col, ship_shapes)
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

  def update_based_on_ship_pattern(probability_grid, row, col)
    # Increase probability of cells in a line extending from the hit cell
    [-1, 1].each do |offset|
      probability_grid[row + offset][col] += Constants::SHIP_PATTERN_PROBABILITY_INCREMENT if valid_coordinates?(row + offset, col)
      probability_grid[row][col + offset] += Constants::SHIP_PATTERN_PROBABILITY_INCREMENT if valid_coordinates?(row, col + offset)
    end
  end
end

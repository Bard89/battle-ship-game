require_relative '../../constants.rb'

module ShipPositionProbability
  def initialize_probability_grid(grid_size = Constants::GRID_SIZE, initial_value = 0.0)
    Array.new(grid_size) { Array.new(grid_size, initial_value) }
  end

  # irregular ship initial probability grid
  def update_grid_with_irregular_ship_probabilities(grid)
    Constants::GRID_SIZE.times do |row|
      Constants::GRID_SIZE.times do |col|
        [:horizontal, :vertical].each do |orientation|
          ship_shape = orientation == :horizontal ? Constants::IRREGULAR_SHIP_HORIZONTAL : Constants::IRREGULAR_SHIP_VERTICAL

          if can_whole_ship_be_here?(row, col, ship_shape)
            update_probability_for_irregular_ship_position(grid, row, col, ship_shape, Constants::SHIP_POSITION_PROBABILITY_INCREMENT, orientation)
          end
        end
      end
    end
  end

  def can_whole_ship_be_here?(row, col, ship_shape)
    half_length_of_the_ship =  ship_shape[0].length / 2 # columns
    half_width_of_the_ship = ship_shape.length / 2 # rows

    return false if col - half_length_of_the_ship < 0
    return false if col + half_length_of_the_ship > Constants::GRID_SIZE - 1
    return false if row - half_width_of_the_ship < 0
    return false if row + half_width_of_the_ship > Constants::GRID_SIZE - 1

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

  # regular ship initial probability grid
  def create_regular_ship_probability_grid
    quarter_grid = create_quarter_grid
    full_grid = reflect_grid(quarter_grid)
    sum_grids(full_grid, full_grid.transpose)
  end

  def create_quarter_grid
    quarter_size = Constants::GRID_SIZE / 2
    quarter_grid = initialize_probability_grid(quarter_size)

    (0...quarter_size).each do |row|
      (0...quarter_size).each do |col|
        increment = [row + 1, col + 1].min
        quarter_grid[row][col] = increment * Constants::SHIP_POSITION_PROBABILITY_INCREMENT
      end
    end

    quarter_grid
  end

  def reflect_grid(quarter_grid)
    full_grid = quarter_grid.map { |row| row + row.reverse }
    full_grid + full_grid.reverse
  end

  def sum_grids(grid1, grid2)
    grid1.each_with_index.map do |row, i|
      row.each_with_index.map do |val, j|
        val + grid2[i][j]
      end
    end
  end
end

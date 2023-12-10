require 'byebug'
require_relative 'helpers.rb'
require_relative 'constants.rb'

class MapGenerator
  include Helpers
  include Constants

  attr_reader :grid

  def initialize
    @grid = Array.new(Constants::GRID_SIZE) { Array.new(Constants::GRID_SIZE, '*') }
    place_ships
  end

  private

  def place_ships
    # Place the irregular ship first ( takes the most space)
    place_irregular_ship

    # Place the regular ships after placing the irregular ship
    place_regular_ships

    puts
    puts "Final grid:"
    print_grid(@grid.flatten.join(''))
  end

  def place_irregular_ship
    placed = false

    until placed
      row, col = rand(Constants::GRID_SIZE - 2), rand(Constants::GRID_SIZE - 4) # Adjust for ship size
      ship_shape = [IRREGULAR_SHIP_HORIZONTAL, IRREGULAR_SHIP_VERTICAL].sample

      if can_place_whole_ship?(row, col, ship_shape)
        place_whole_ship(row, col, ship_shape)
        placed = true
      end
    end
  end

  def place_regular_ships
    REGULAR_SHIPS.each_with_index do |ship_size, index|
      placed = false

      until placed
        row, col, horizontal = rand(Constants::GRID_SIZE), rand(Constants::GRID_SIZE), [true, false].sample
        next unless can_place_regular_ship?(row, col, ship_size, horizontal)

        ship_size.times do |i|
          if horizontal
            grid[row][col + i] = 'S'
          else
            grid[row + i][col] = 'S'
          end
        end

        # uncomment to see the grid after each ship is placed
        #
        puts
        puts "Placed ship n. #{index} on row: #{row}, column: #{col} of size #{ship_size}, #{horizontal ? 'horizontally' : 'vertically'}"
        print_grid(@grid.flatten.join(''))

        placed = true
      end
    end
  end

  def can_place_whole_ship?(row, col, ship_shape)
    ship_shape.each_with_index do |ship_row, r|
      ship_row.each_with_index do |cell, c|
        # Check grid boundaries
        return false unless valid_coordinates?(row + r, col + c)
        # Check if the cell is already occupied ( can't happen now since we are placing the irregular ship first)
        return false if @grid[row + r][col + c] != '*' && (cell == 'S' || cell == 'I')
      end
    end

    true
  end

  def place_whole_ship(row, col, ship_shape)
    ship_shape.each_with_index do |ship_row, r|
      ship_row.each_with_index do |cell, c|
        grid[row + r][col + c] = cell if (cell == 'S' || cell == 'I')
      end
    end
  end

  # Check if the ship can be placed at the given coordinates without overlapping or going out of bounds and with a gap of at least one cell between ships
  def can_place_regular_ship?(row, col, ship_size, horizontal)
    if horizontal
      return false if col + ship_size > Constants::GRID_SIZE
      ship_cells = (col...(col + ship_size)).map { |c| [row, c] }
    else
      return false if row + ship_size > Constants::GRID_SIZE
      ship_cells = (row...(row + ship_size)).map { |r| [r, col] }
    end

    surrounding_cells = ship_cells.flat_map do |r, c|
      [
        [r - 1, c], [r + 1, c],    # cells above and below
        [r, c - 1], [r, c + 1],    # cells to the left and right
        [r - 1, c - 1], [r + 1, c + 1], # diagonal cells
        [r + 1, c - 1], [r - 1, c + 1]
      ]
    end.uniq

    # Check all cells for ship placement and surrounding for gaps
    (ship_cells + surrounding_cells).all? do |r, c|
      next true if r < 0 || r >= Constants::GRID_SIZE || c < 0 || c >= Constants::GRID_SIZE # ignore out of bounds
      @grid[r][c] == '*'
    end
  end

  def surrounding_cells(row, col)
    # Returns the surrounding cells, including diagonals
    (-1..1).flat_map do |row_offset|
      (-1..1).map do |col_offset|
        [row + row_offset, col + col_offset]
      end
    end
  end
end

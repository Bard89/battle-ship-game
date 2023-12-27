require 'byebug'
require_relative 'helpers/print_helpers.rb'
require_relative 'helpers/algo_helpers.rb'
require_relative 'constants.rb'

class MapGenerator
  include AlgoHelpers
  include PrintHelpers
  include Constants

  attr_reader :grid

  def initialize
    @grid = Array.new(Constants::GRID_SIZE) { Array.new(Constants::GRID_SIZE, '*') }
    place_ships
  end

  def place_ships
    place_irregular_ship
    place_regular_ships
    puts "\nFinal grid:"
    print_grid(@grid.flatten.join(''))
  end

  def place_irregular_ship
    placed = false

    until placed
      row, col = rand(Constants::GRID_SIZE - 2), rand(Constants::GRID_SIZE - 4)
      ship_shape = [IRREGULAR_SHIP_HORIZONTAL, IRREGULAR_SHIP_VERTICAL].sample

      if can_place_whole_ship?(row, col, ship_shape)
        place_whole_ship(row, col, ship_shape)
        placed = true
      end
    end
  end

  def can_place_whole_ship?(row, col, ship_shape)
    ship_shape.each_with_index do |ship_row, r|
      ship_row.each_with_index do |cell, c|
        # Check grid boundaries plus if the cell is already occupied ( can't happen now since we are placing the irregular ship first)
        return false unless valid_coordinates?(row + r, col + c) && (cell != 'S' && cell != 'I' || grid[row + r][col + c] == '*')
      end
    end
    true
  end

  def place_regular_ships
    REGULAR_SHIPS.each do |ship_size|
      placed = false

      until placed
        row, col, horizontal = rand(Constants::GRID_SIZE), rand(Constants::GRID_SIZE), [true, false].sample
        next unless can_place_regular_ship?(row, col, ship_size, horizontal)

        ship_size.times { |i| horizontal ? grid[row][col + i] = 'S' : grid[row + i][col] = 'S' }
        placed = true
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

    surrounding_cells = ship_cells.flat_map { |r, c| surrounding_cells(r, c) }.uniq

    # Check all cells for ship placement and surrounding for gaps
    (ship_cells + surrounding_cells).all? do |r, c|
      next true unless valid_coordinates?(r, c)

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

  def place_whole_ship(row, col, ship_shape)
    ship_shape.each_with_index do |ship_row, r|
      ship_row.each_with_index do |cell, c|
        grid[row + r][col + c] = cell if (cell == 'S' || cell == 'I')
      end
    end
  end
end

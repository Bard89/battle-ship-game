require 'byebug'
# require_relative 'test_battleship_game.rb'

class MockBattleshipAPI
  GRID_SIZE = 12
  SHIPS = [4, 3, 3, 2] # Need to add the weird shape ship

  def initialize
    @grid = Array.new(GRID_SIZE) { Array.new(GRID_SIZE, '*') }
    place_ships
  end

  def fire(row, column)
    return "Invalid coordinates" unless valid_coordinates?(row, column)

    cell = @grid[row][column]
    if cell == '.' # Miss
      @grid[row][column] = '*'
      "Miss"
    elsif cell == '*' || cell == 'X' # Already hit
      "Already hit"
    else # Hit
      @grid[row][column] = 'X'
      "Hit"
    end
  end

  def reset
    @grid = Array.new(GRID_SIZE) { Array.new(GRID_SIZE, '.') }
    place_ships
  end

  private

  def place_ships
    # Place the irregular ship first
    place_irregular_ship

    # Place the regular ships
    SHIPS.each do |ship_size|
      placed = false

      until placed
        row, col, horizontal = rand(GRID_SIZE), rand(GRID_SIZE), [true, false].sample
        next unless can_place_regular?(row, col, ship_size, horizontal)

        ship_size.times do |i|
          if horizontal
            @grid[row][col + i] = 'S'
          else
            @grid[row + i][col] = 'S'
          end
        end

        # puts
        # puts "Placed #{row}, #{col} ship of size #{ship_size}, #{horizontal ? 'horizontal' : 'vertical'}"
        # print_grid(@grid.flatten.join(''))
        placed = true
      end
    end

    # puts
    # puts "Final grid:"
    # print_grid(@grid.flatten.join(''))
  end

  def place_irregular_ship
    horizontal_ship = [
      ['*', 'I', '*', 'I', '*'],
      ['I', 'I', 'I', 'I', 'I'],
      ['*', 'I', '*', 'I', '*']
    ]
    vertical_ship = horizontal_ship.transpose

    placed = false
    until placed
      row, col = rand(GRID_SIZE - 2), rand(GRID_SIZE - 4) # Adjust for ship size
      ship_shape = [horizontal_ship, vertical_ship].sample

      if can_place_whole_ship?(row, col, ship_shape)
        place_whole_ship(row, col, ship_shape)
        placed = true
      end
    end
  end

  def can_place_whole_ship?(row, col, ship_shape)
    ship_shape.each_with_index do |ship_row, r|
      ship_row.each_with_index do |cell, c|
        # Check grid boundaries
        return false unless valid_coordinates?(row + r, col + c)
        # Check if the cell is already occupied
        return false if @grid[row + r][col + c] != '*' && cell == 'I'
      end
    end
    true
  end

  def place_whole_ship(row, col, ship_shape)
    ship_shape.each_with_index do |ship_row, r|
      ship_row.each_with_index do |cell, c|
        @grid[row + r][col + c] = cell if cell == 'I'
      end
    end
  end

  # Check if the ship can be placed at the given coordinates without overlapping or going out of bounds and with a gap of at least one cell between ships
  def can_place_regular?(row, col, ship_size, horizontal)
    if horizontal
      return false if col + ship_size > GRID_SIZE
      ship_cells = (col...(col + ship_size)).map { |c| [row, c] }
    else
      return false if row + ship_size > GRID_SIZE
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
      next true if r < 0 || r >= GRID_SIZE || c < 0 || c >= GRID_SIZE # ignore out of bounds
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

  def valid_coordinates?(row, column)
    row.between?(0, GRID_SIZE - 1) && column.between?(0, GRID_SIZE - 1)
  end

  def print_grid(grid_string)
    grid_string.chars.each_slice(12).with_index do |row, index|
      formatted_row_number = format('Row %-3d:', index) # Adjusts the spacing for row numbers
      puts "#{formatted_row_number} #{row.join(' ')}"
    end
  end
end

byebug
api = MockBattleshipAPI.new




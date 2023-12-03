require 'byebug'
# require_relative 'test_battleship_game.rb'

class MockBattleshipAPI
  GRID_SIZE = 12
  SHIPS = [5, 4, 3, 3, 2] # Need to add the weird shape ship

  def initialize
    @grid = Array.new(GRID_SIZE) { Array.new(GRID_SIZE, '*') }
    place_ships
  end

  # def fire(row, column)
  #   return "Invalid coordinates" unless valid_coordinates?(row, column)
  #
  #   cell = @grid[row][column]
  #   if cell == '.' # Miss
  #     @grid[row][column] = '*'
  #     "Miss"
  #   elsif cell == '*' || cell == 'X' # Already hit
  #     "Already hit"
  #   else # Hit
  #     @grid[row][column] = 'X'
  #     "Hit"
  #   end
  # end
  #
  # def reset
  #   @grid = Array.new(GRID_SIZE) { Array.new(GRID_SIZE, '.') }
  #   place_ships
  # end

  private

  def place_ships
    SHIPS.each do |ship_size|
      placed = false

      until placed
        row, col, horizontal = rand(GRID_SIZE), rand(GRID_SIZE), [true, false].sample
        next unless can_place?(row, col, ship_size, horizontal)

        ship_size.times do |i|
          if horizontal
            @grid[row][col + i] = 'S'
          else
            @grid[row + i][col] = 'S'
          end
        end

        puts "Placed #{row}, #{col} ship of size #{ship_size}, #{horizontal ? 'horizontal' : 'vertical'}"
        # print_grid(@grid.flatten.join(''))
        placed = true
      end
    end
    print_grid(@grid.flatten.join(''))
  end

  def can_place?(row, col, ship_size, horizontal)
    # Check if the ship can be placed at the given coordinates without overlapping or going out of bounds
    if horizontal
      return false if col + ship_size > GRID_SIZE

      (col...(col + ship_size)).each do |i|
        return false if @grid[row][i] != '*'
      end
    else
      return false if row + ship_size > GRID_SIZE

      (row...(row + ship_size)).each do |i|
        return false if @grid[i][col] != '*'
      end
    end

    true
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
MockBattleshipAPI.new




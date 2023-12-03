require 'byebug'
require_relative 'map_generator.rb'
# require_relative 'test_battleship_game.rb'

class MockBattleshipAPI
  def initialize
    map_generator = MapGenerator.new
    @grid = map_generator.grid
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
end

byebug
api = MockBattleshipAPI.new




require_relative 'map_generator.rb'
require_relative 'helpers.rb'
require_relative 'constants.rb'
require_relative 'algos.rb'

require 'byebug'
require 'set'


class MockBattleshipAPI
  include Helpers
  include Constants

  attr_reader :move_count, :shots, :grid

  def initialize
    @grid = MapGenerator.new.grid
    @shots = Set.new
    @move_count = 0
  end

  def fire(row, column)
    # Validate the coordinates
    return { "error" => "Invalid coordinates" } unless valid_coordinates?(row, column)

    # Register the shot
    shot_key = [row, column]
    @move_count += 1 if @shots.add?(shot_key)

    # Determine the result of the shot
    cell = @grid[row][column]
    hit = 'S' == cell
    @grid[row][column] = hit ? 'X' : '.' if cell == '*' || hit

    parsed_response(hit)
  end

  def reset
    @grid = MapGenerator.new
    @shots.clear
    @move_count = 0
  end

  def parsed_response(hit)
    parsed_response = {
      "grid" => @grid.flatten.join,
      "cell" => hit ? 'X' : '',
      "result" => hit,
      "moveCount" => @move_count,
      "finished" => finished?
    }

    # just help for me when I debug to see the grid
    puts self.print_grid(parsed_response['grid'])

    parsed_response
  end

  private

  def valid_coordinates?(row, column)
    row.between?(0, Constants::GRID_SIZE - 1) && column.between?(0, Constants::GRID_SIZE - 1)
  end

  def finished?
    !@grid.any? { |row| row.include?('S') || row.include?('I') }
  end
end

api = MockBattleshipAPI.new




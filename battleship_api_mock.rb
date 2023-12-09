require_relative 'map_generator.rb'
require_relative 'helpers.rb'
require_relative 'constants.rb'
require_relative 'algos/brute_force.rb'
require_relative 'algos/hunt_and_target.rb'
require_relative 'algos/probability_density.rb'

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
    return { "error" => "Invalid coordinates" } unless valid_coordinates?(row, column)

    count_shot(row, column)
    process_shot_result(row, column)
  end

  def parsed_response(hit)
    parsed_response = {
      "grid" => grid.flatten.join,
      "cell" => hit ? 'X' : '',
      "result" => hit,
      "moveCount" => move_count,
      "finished" => finished?
    }

    puts self.print_grid(parsed_response['grid'])

    parsed_response
  end

  def finished?
    !grid.any? { |row| row.include?('S') }
  end

  private

  def count_shot(row, column)
    @move_count += 1 if shots.add?([row, column])
  end

  def process_shot_result(row, column)
    cell = grid[row][column]
    hit = cell == 'S'

    update_grid_for_shot(row, column, hit)

    parsed_response(hit)
  end

  def update_grid_for_shot(row, column, hit)
    if hit || grid[row][column] == '*'
      grid[row][column] = hit ? 'X' : '.'
    end
  end
end




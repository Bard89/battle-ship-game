require_relative 'map_generator.rb'
require_relative 'helpers/print_helpers.rb'
require_relative 'helpers/solver_helpers.rb'
require_relative 'constants.rb'
require_relative 'algos/brute_force.rb'
require_relative 'algos/hunt_and_target.rb'
require_relative 'algos/probability_density.rb'
require_relative 'algos/main_probability_density_modified.rb'

require 'byebug'
require 'set'
require 'awesome_print'


class MockBattleshipAPI
  include PrintHelpers
  include Constants

  attr_reader :move_count, :shots, :grid, :avengerAvailable, :irregular_ship_cells

  def initialize
    @grid = MapGenerator.new.grid
    @shots = Set.new
    @move_count = 0
    @avengerAvailable = false
    @irregular_ship_cells = find_irregular_ship_cells

    # unsure what it will return, probably not necessary here, in the real game there is 200 games / maps to play in one go
    # @map_count = 0
  end

  def fire(row, column)
    return { "error" => "Invalid coordinates" } unless valid_coordinates?(row, column)

    count_shot(row, column)
    process_shot_result(row, column)
  end

  # TODO; add fire for the avengers

  def parsed_response(hit)
    parsed_response = {
      "grid" => grid.flatten.join,
      "cell" => hit ? 'X' : '',
      "result" => hit,
      "moveCount" => move_count,
      "finished" => finished?,
      "avengerAvailable" => avengerAvailable
    }

    ap parsed_response

    parsed_response
  end

  def finished?
    !grid.any? { |row| row.include?('S') || row.include?('I') }
  end

  private

  def count_shot(row, column)
    @move_count += 1 if shots.add?([row, column])
  end

  def process_shot_result(row, column)
    cell = grid[row][column]
    hit = (cell == 'S' || cell == 'I')

    update_grid_for_shot(row, column, hit)
    check_irregular_ship_sunk

    parsed_response(hit)
  end

  def update_grid_for_shot(row, column, hit)
    if hit || grid[row][column] == '*'
      grid[row][column] = hit ? 'X' : '.'
    end
  end

  def check_irregular_ship_sunk
    if @irregular_ship_cells.all? { |r, c| grid[r][c] == 'X' }
      @avengerAvailable = true
    end
  end

  def find_irregular_ship_cells
    grid.each_with_index.flat_map do |row, r_index|
      row.each_with_index.map { |cell, c_index| [r_index, c_index] if cell == 'I' }.compact
    end
  end
end




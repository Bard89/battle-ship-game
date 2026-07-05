require_relative 'map_generator.rb'
require_relative 'helpers/print_helpers.rb'
require_relative 'helpers/algo_helpers.rb'
require_relative 'constants.rb'

require 'byebug'
require 'set'
require 'awesome_print'

# Faithful single-map mock of the Panaxeo Battleships API.
#
# Response shape follows the real FireResponse / AvengerFireResponse docs:
#   grid   - 144 chars, '*' unknown, 'X' revealed ship, '.' revealed water
#            (never leaks unrevealed ship positions)
#   cell   - outcome of this shot: 'X' hit, '.' miss, '' invalid (already revealed)
#   result - whether the fire action was valid (NOT whether it hit!)
#   avengerAvailable - true once the helicarrier is destroyed, until the one avenger use
#   moveCount        - valid moves only; repeated shots at a revealed cell don't count
#   finished         - this map is completed (the real API tracks 200 maps per game;
#                      the mock plays a single map, so finished == map done)
#
# Assumption (real API is gone, wording ambiguous): the avenger stays available
# from the helicarrier's destruction until used, rather than expiring after one turn.
#
# avengerResult mapPoints follow the documented convention: x is the ROW
# ("vertical position") and y is the COLUMN, exactly like the /fire/:row/:column
# path parameters.
class BattleshipAPIMock
  include AlgoHelpers
  include PrintHelpers
  include Constants

  attr_reader :move_count, :avenger_available
  # truth for tests/verification only - algorithms must not read these
  # (grid is the unmasked board with S/I ship positions; the API surface is
  # the masked "grid" string in the responses)
  attr_reader :grid, :ships, :revealed

  def initialize(seed: nil, verbose: false)
    @rng = seed.nil? ? Random.new : Random.new(seed)
    @verbose = verbose
    @grid = MapGenerator.new(rng: @rng, verbose: verbose).grid
    @revealed = Set.new
    @move_count = 0
    @avenger_available = false
    @avenger_used = false
    @ships = find_ships
    @total_ship_cells = @ships.sum { |ship| ship[:cells].size }
    @revealed_ship_cells = 0
  end

  def fire(row, column)
    return { "error" => "Invalid values for row or column" } unless valid_coordinates?(row, column)

    cell = shoot(row, column)
    parsed_response(cell)
  end

  def fire_with_avenger(row, column, avenger)
    return { "error" => "Invalid value for avenger" } unless AVENGERS.include?(avenger)
    return { "error" => "Avenger unavailable" } unless avenger_available
    return { "error" => "Invalid values for row or column" } unless valid_coordinates?(row, column)

    # defensive: an avenger shot at an already revealed cell is invalid and not consumed
    return parsed_response('', avenger_result: []) if @revealed.include?([row, column])

    cell = shoot(row, column)
    @avenger_used = true
    @avenger_available = false

    avenger_result =
      case avenger
      when 'hulk' then hulk_result(row, column)
      when 'ironman' then ironman_result
      when 'thor' then thor_result
      end

    parsed_response(cell, avenger_result: avenger_result)
  end

  def finished?
    @revealed_ship_cells == @total_ship_cells
  end

  private

  # Reveals the cell and counts the move. Returns 'X'/'.' for a valid shot, '' otherwise.
  def shoot(row, column)
    return '' unless @revealed.add?([row, column])

    @move_count += 1
    reveal(row, column)
  end

  # Reveals without counting a move (thor/hulk side effects). Returns 'X'/'.'.
  def reveal(row, column)
    @revealed.add([row, column])

    if ship_cell?(row, column)
      @revealed_ship_cells += 1
      check_irregular_ship_sunk
      'X'
    else
      '.'
    end
  end

  def ship_cell?(row, column)
    cell = @grid[row][column]
    cell == 'S' || cell == 'I'
  end

  def check_irregular_ship_sunk
    return if @avenger_used || @avenger_available

    helicarrier = @ships.find { |ship| ship[:irregular] }
    @avenger_available = helicarrier[:cells].all? { |cell| @revealed.include?(cell) }
  end

  # hulk destroys the whole ship at the hit position
  def hulk_result(row, column)
    ship = @ships.find { |candidate| candidate[:cells].include?([row, column]) }
    return [] unless ship

    ship[:cells].map do |r, c|
      reveal(r, c) unless @revealed.include?([r, c])
      { "mapPoint" => { "x" => r, "y" => c }, "hit" => true }
    end
  end

  # ironman reveals (to the player only) one map point of the smallest non-destroyed ship
  def ironman_result
    target_ship = @ships
                  .reject { |ship| ship[:cells].all? { |cell| @revealed.include?(cell) } }
                  .min_by { |ship| ship[:cells].size }
    return [] unless target_ship

    hidden_cells = target_ship[:cells].reject { |cell| @revealed.include?(cell) }
    row, column = hidden_cells.sample(random: @rng)
    [{ "mapPoint" => { "x" => row, "y" => column }, "hit" => true }]
  end

  # thor reveals up to 10 random untouched map points
  def thor_result
    untouched = all_coordinates.reject { |cell| @revealed.include?(cell) }
    untouched.sample(THOR_EXTRA_POINTS, random: @rng).map do |row, column|
      hit = reveal(row, column) == 'X'
      { "mapPoint" => { "x" => row, "y" => column }, "hit" => hit }
    end
  end

  def all_coordinates
    (0...Constants::GRID_SIZE).to_a.product((0...Constants::GRID_SIZE).to_a)
  end

  def parsed_response(cell, avenger_result: nil)
    response = {
      "grid" => masked_grid,
      "cell" => cell,
      "result" => cell != '',
      "avengerAvailable" => avenger_available,
      "mapId" => 0,
      "mapCount" => 1,
      "moveCount" => move_count,
      "finished" => finished?
    }
    response["avengerResult"] = avenger_result unless avenger_result.nil?

    ap response if @verbose

    response
  end

  def masked_grid
    Constants::GRID_SIZE.times.flat_map do |row|
      Constants::GRID_SIZE.times.map do |column|
        if !@revealed.include?([row, column])
          '*'
        elsif ship_cell?(row, column)
          'X'
        else
          '.'
        end
      end
    end.join
  end

  # ships are orthogonally connected components of the truth grid
  # (the no-touch rule guarantees components == ships)
  def find_ships
    seen = Set.new
    ships = []

    Constants::GRID_SIZE.times do |row|
      Constants::GRID_SIZE.times do |column|
        next if !ship_cell?(row, column) || seen.include?([row, column])

        cells = []
        stack = [[row, column]]
        until stack.empty?
          r, c = stack.pop
          next if seen.include?([r, c])

          seen.add([r, c])
          cells << [r, c]
          [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]].each do |nr, nc|
            stack << [nr, nc] if valid_coordinates?(nr, nc) && ship_cell?(nr, nc) && !seen.include?([nr, nc])
          end
        end

        ships << { cells: cells.sort, irregular: cells.any? { |r, c| @grid[r][c] == 'I' } }
      end
    end

    ships
  end
end

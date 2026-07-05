# theoretically the most efficient strategy to solve the battleship game
# it's a bit tricky to implement it properly and to set the weights properly

require_relative '../map_generator.rb'
require_relative '../helpers/print_helpers.rb'
require_relative '../helpers/algo_helpers.rb'
require_relative '../constants.rb'
require 'byebug'

module ProbabilityDensity
  extend PrintHelpers
  extend AlgoHelpers
  include Constants

  module_function

  def probability_density(api)
    probability_grid = initialize_probability_grid
    # what we know so far, built purely from API responses: '*' unknown, 'X' hit, '.' miss
    known_grid = Array.new(Constants::GRID_SIZE) { Array.new(Constants::GRID_SIZE, '*') }

    until api.finished?
      target = find_gap_between_hits(known_grid) || find_sequence_to_follow(known_grid) || highest_probability_cell(probability_grid, known_grid)
      row, col = target

      if AlgoHelpers.verbose
        puts "\nTargeting Row #{row}, Col #{col}, has the highest probability of #{(probability_grid[row][col] * 100).round(2)}"
      end

      response = api.fire(row, col)
      known_grid = response["grid"].chars.each_slice(Constants::GRID_SIZE).to_a
      update_probability_grid(probability_grid, row, col, response["cell"] == 'X')

      if AlgoHelpers.verbose
        puts
        print_probability_grid(probability_grid)
        puts "move count: #{response["moveCount"]}"
      end
    end
  end

  def initialize_probability_grid
    Array.new(Constants::GRID_SIZE) { Array.new(Constants::GRID_SIZE, 1.0 / (Constants::GRID_SIZE * Constants::GRID_SIZE)) }
  end

  def highest_probability_cell(probability_grid, known_grid)
    best = nil
    best_prob = -Float::INFINITY

    probability_grid.each_with_index do |row, r_index|
      row.each_with_index do |prob, c_index|
        next unless known_grid[r_index][c_index] == '*' # only unrevealed cells are valid targets

        if prob > best_prob
          best_prob = prob
          best = [r_index, c_index]
        end
      end
    end

    best
  end

  def update_probability_grid(grid, row, col, hit)
    grid[row][col] = 0 # the cell is revealed either way, never target it again

    if hit
      adjust_probabilities(grid, row, col, :increase)
    else
      adjust_probabilities(grid, row, col, :decrease)
    end
  end

  def adjust_probabilities(grid, row, col, adjustment)
    adjustment_factor = adjustment == :increase ? 1.1 : 0.9
    # Iterate through the surrounding cells
    (-1..1).each do |row_offset|
      (-1..1).each do |col_offset|
        new_row, new_col = row + row_offset, col + col_offset
        if valid_coordinates?(new_row, new_col)
          # Adjust the probability of the cell
          grid[new_row][new_col] *= adjustment_factor
        end
      end
    end

    normalize_probabilities(grid) if adjustment == :decrease
  end

  def normalize_probabilities(grid)
    total_probability = grid.flatten.sum
    return if total_probability.zero?

    grid.each_with_index do |row, r_index|
      row.each_with_index do |prob, c_index|
        grid[r_index][c_index] /= total_probability
      end
    end
  end

  # shoot the gap when two hits sit one apart in a line (X * X)
  def find_gap_between_hits(grid)
    Constants::GRID_SIZE.times do |row|
      (Constants::GRID_SIZE - 2).times do |col|
        # Check for horizontal pattern
        if grid[row][col] == 'X' && grid[row][col + 2] == 'X' && grid[row][col + 1] == '*'
          return [row, col + 1]
        end
        # Check for vertical pattern if within grid bounds
        if row < Constants::GRID_SIZE - 2
          if grid[row][col] == 'X' && grid[row + 2][col] == 'X' && grid[row + 1][col] == '*'
            return [row + 1, col]
          end
        end
      end
    end
    nil
  end

  # checking for continuous ships and their sizes
  def find_sequence_to_follow(grid)
    Constants::GRID_SIZE.times do |row|
      Constants::GRID_SIZE.times do |col|
        next unless grid[row][col] == 'X' # Start from a hit

        # Check horizontal and vertical sequences
        horizontal_seq = check_horizontal_sequence(grid, row, col)
        vertical_seq = check_vertical_sequence(grid, row, col)

        if horizontal_seq
          next_target = extend_sequence(grid, horizontal_seq, :horizontal)
          return next_target if next_target
        end

        if vertical_seq
          next_target = extend_sequence(grid, vertical_seq, :vertical)
          return next_target if next_target
        end
      end
    end
    nil
  end

  def extend_sequence(grid, sequence, orientation)
    first_hit, last_hit = sequence.first, sequence.last

    if orientation == :horizontal
      left_cell = [first_hit[0], first_hit[1] - 1]
      right_cell = [last_hit[0], last_hit[1] + 1]
      return left_cell if valid_target?(grid, left_cell)
      return right_cell if valid_target?(grid, right_cell)
    elsif orientation == :vertical
      top_cell = [first_hit[0] - 1, first_hit[1]]
      bottom_cell = [last_hit[0] + 1, last_hit[1]]
      return top_cell if valid_target?(grid, top_cell)
      return bottom_cell if valid_target?(grid, bottom_cell)
    end

    nil
  end

  def valid_target?(grid, cell)
    row, col = cell
    valid_coordinates?(row, col) && grid[row][col] == '*'
  end

  def check_horizontal_sequence(grid, row, col)
    sequence = []
    # Check to the right
    while col < Constants::GRID_SIZE && grid[row][col] == 'X'
      sequence << [row, col]
      col += 1
    end
    sequence.length > 1 ? sequence : nil
  end

  def check_vertical_sequence(grid, row, col)
    sequence = []
    # Check downwards
    while row < Constants::GRID_SIZE && grid[row][col] == 'X'
      sequence << [row, col]
      row += 1
    end
    sequence.length > 1 ? sequence : nil
  end
end

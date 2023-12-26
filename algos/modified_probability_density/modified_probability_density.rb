require_relative '../../helpers/print_helpers'
require_relative '../../helpers/algo_helpers'
require_relative '../../map_generator.rb'
require_relative '../../constants.rb'
require_relative '../../battleship_api_mock.rb'
require_relative 'ship_position_probability.rb'
require_relative 'hit_and_miss_probability.rb'

require 'byebug'

module ModifiedProbabilityDensity
  extend AlgoHelpers
  extend PrintHelpers
  extend ShipPositionProbability
  extend HitAndMissProbability
  include Constants

  @hit_ships = {}
  @confirmed_sunk_ships = []

  module_function

  def probability_density(api)
    targeted_cells = Set.new

    probability_grid_irregular = initialize_probability_grid
    probability_grid_combined = initialize_probability_grid

    update_grid_with_irregular_ship_probabilities(probability_grid_irregular)
    # update_grid_with_regular_ship_probabilities(probability_grid_combined)
    update_grid_with_irregular_ship_probabilities(probability_grid_combined)

    puts "Irregular ship probability grid:"
    print_probability_grid(probability_grid_combined)
    puts "Regular ship probability grid:"
    print_probability_grid(probability_grid_irregular)


    until api.finished? # until the game is over
      target_row, target_col = nil

    # just to optimize the game, to update the probabilities right
    # until api.avengerAvailable
      if api.avengerAvailable # if the biggest ship is sunk, use the avenger
        target_row, target_col = target_ship(probability_grid_combined, targeted_cells)
      else
        target_row, target_col = target_ship(probability_grid_irregular, targeted_cells)
      end

        if targeted_cells.include?([target_row, target_col])
          raise "Already targeted cell #{target_row}, #{target_col}"
        end

        targeted_cells.add([target_row, target_col])


        result = api.fire(target_row, target_col)
        update_probability(probability_grid_irregular, target_row, target_col, result['result'])
        update_probability(probability_grid_combined, target_row, target_col, result['result'])


        if result['result']
          ship_hits = record_hit(target_row, target_col)
          if ship_sunk?(ship_hits, probability_grid_irregular)
            update_for_sunk_ship(ship_hits, probability_grid_irregular)
            @confirmed_sunk_ships.concat(ship_hits)
            @hit_ships.delete(ship_hits.object_id)
          end
        end

        targeted_cells.add([target_row, target_col])


        purple_bold_start = "\e[1m\e[38;5;198m"
        purple_bold_end = "\e[0m"

        puts "#{purple_bold_start}Targeted#{purple_bold_end}"
        api.print_target_grid(result['grid'], target_row, target_col)
        puts "Irregular ship probability grid:"
        print_probability_grid(probability_grid_irregular)
        puts
        puts "Regular ship probability grid:"
        print_probability_grid(probability_grid_combined)
    end
  end

  def target_ship(probability_grid, targeted_cells)
    highest_probability = -Float::INFINITY
    target_position = [-1, -1]

    probability_grid.each_with_index do |row, r_idx|
      row.each_with_index do |prob, c_idx|
        cell_position = [r_idx, c_idx]

        if prob > highest_probability && !targeted_cells.include?(cell_position)
          highest_probability = prob
          target_position = cell_position
        end
      end
    end

    if target_position == [-1, -1]
      raise "No valid target found. All cells may have been targeted."
    end

    target_position
  end

  def overlaps_missed_cell?(ship_placement, row, col, missed_row, missed_col)
    ship_placement.each_with_index do |ship_row, r_offset|
      ship_row.each_with_index do |cell, c_offset|
        # Calculate the absolute position of the cell in the grid
        absolute_row = row + r_offset
        absolute_col = col + c_offset

        # Check if the absolute position matches the missed cell
        return true if absolute_row == missed_row && absolute_col == missed_col
      end
    end
    false
  end

  # Record a hit and determine if it's part of a known ship
  def record_hit(row, col)
    # Check if this hit connects to an existing ship
    @hit_ships.each do |hits|
      if hits.any? { |hit_row, hit_col| adjacent?(hit_row, hit_col, row, col) }
        hits << [row, col]
        return hits
      end
    end
    # Otherwise, start tracking a new ship
    new_ship_hits = [[row, col]]
    @hit_ships[new_ship_hits.object_id] = new_ship_hits
    new_ship_hits
  end

  # Check if two cells are adjacent (diagonals not considered)
  def adjacent?(row1, col1, row2, col2)
    (row1 == row2 && (col1 - col2).abs == 1) || (col1 == col2 && (row1 - row2).abs == 1)
  end

  # Determine if the ship is sunk
  def ship_sunk?(ship_hits, probability_grid)
    ship_hits.all? do |hit_row, hit_col|
      # If all adjacent cells are either hit or have a probability of 0, the ship is considered sunk
      adjacent_cells(hit_row, hit_col).all? do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] == 0 || @confirmed_sunk_ships.include?([adj_row, adj_col])
      end
    end
  end

  # Get a list of adjacent cells
  def adjacent_cells(row, col)
    [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]].select do |adj_row, adj_col|
      valid_coordinates?(adj_row, adj_col)
    end
  end

  # Method to update the probability grid for a sunk ship
  def update_for_sunk_ship(ship_hits, probability_grid)
    ship_hits.each do |hit_row, hit_col|
      # Set the probability of the hit cells to 0
      probability_grid[hit_row][hit_col] = 0
      # Also set the probability of the adjacent cells to 0
      adjacent_cells(hit_row, hit_col).each do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] = 0 unless @confirmed_sunk_ships.include?([adj_row, adj_col])
      end
    end
  end
end

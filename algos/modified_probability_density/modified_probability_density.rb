require_relative '../../helpers/print_helpers'
require_relative '../../helpers/algo_helpers'
require_relative '../../map_generator.rb'
require_relative '../../constants.rb'
require_relative '../../battleship_api_mock.rb'
require_relative 'ship_position_probability.rb'
require_relative 'hit_and_miss_probability.rb'
require_relative 'ship_sunk_or_not_probability.rb'

require 'byebug'

module ModifiedProbabilityDensity
  extend AlgoHelpers
  extend PrintHelpers
  extend ShipPositionProbability
  extend HitAndMissProbability
  extend ShipSunkOrNotProbability
  include Constants

  module_function

  def probability_density(api)
    initialize_ship_tracking
    targeted_cells = Set.new

    probability_grid_irregular = create_irregular_ship_probability_grid
    probability_grid_regular = create_regular_ship_probability_grid

    # update_grid_with_irregular_ship_probabilities(probability_grid_regular)
    # probability_grid_combined = probability_grid_regular

    puts "Irregular ship probability grid:"
    print_probability_grid(probability_grid_irregular)
    puts "Regular ship probability grid:"
    print_probability_grid(probability_grid_regular)
    # puts "Combined ship probability grid:"
    # print_probability_grid(probability_grid_combined)

    until api.finished? # until the game is over
      target_row, target_col = nil

    # just to optimize the game, to update the probabilities right
    # until api.avengerAvailable
      if api.avengerAvailable # if the biggest ship is sunk, use the avenger
        target_row, target_col = target_ship(probability_grid_regular, targeted_cells)
      else
        target_row, target_col = target_ship(probability_grid_irregular, targeted_cells)
      end

        raise "Already targeted cell #{target_row}, #{target_col}" if targeted_cells.include?([target_row, target_col])

        puts "Hit ships:#{@partially_sunk_ships}"
        puts "Confirmed sunk ships:#{@fully_sunk_ships}"
        # sleep(0.3)
        targeted_cells.add([target_row, target_col])
        result = api.fire(target_row, target_col)

        update_probabilities_after_firing(target_row, target_col, result, probability_grid_irregular, api)
        update_probabilities_after_firing(target_row, target_col, result, probability_grid_regular, api)

        if api.avengerAvailable
          print_target_and_probability_grid(false, probability_grid_irregular, target_row, target_col, result)
        else
          print_target_and_probability_grid(true, probability_grid_regular, target_row, target_col, result)
        end
    end
  end

  def update_probabilities_after_firing(target_row, target_col, result, probability_grid, api)
    update_adjacent_cells(probability_grid, target_row, target_col, result['result'])
    update_hit_or_miss_probability(probability_grid, target_row, target_col, result['result'])

    # the algo works better without the ship sunk or not, but the problem with current algo is that it doesn't know when to stop
    # shooting around the ship. This was an attempt to solve that. Not fully functional though yet. As of now just making everything worse
    # uncomment to develop further
    # update_ship_sunk_or_not(probability_grid, target_row, target_col, result['result'], api)
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
    raise "No valid target found. All cells may have been targeted." if target_position == [-1, -1]

    target_position
  end
end

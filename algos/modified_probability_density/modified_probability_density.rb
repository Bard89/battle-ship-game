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
    @hit_ships = {}
    @confirmed_sunk_ships = []
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

        if targeted_cells.include?([target_row, target_col])
          raise "Already targeted cell #{target_row}, #{target_col}"
        end

        targeted_cells.add([target_row, target_col])

        result = api.fire(target_row, target_col)

        update_adjacent_cells(probability_grid_irregular, target_row, target_col, result['result'])
        update_adjacent_cells(probability_grid_regular, target_row, target_col, result['result'])

        update_hit_or_miss_probability(probability_grid_irregular, target_row, target_col, result['result'])
        update_hit_or_miss_probability(probability_grid_regular, target_row, target_col, result['result'])

        update_ship_sunk_or_not(result, target_row, target_col, probability_grid_irregular)
        update_ship_sunk_or_not(result, target_row, target_col, probability_grid_regular)

        targeted_cells.add([target_row, target_col])

        purple_bold_start = "\e[1m\e[38;5;198m"
        purple_bold_end = "\e[0m"
        puts "#{purple_bold_start}Targeted#{purple_bold_end}"
        api.print_target_grid(result['grid'], target_row, target_col)
        if api.avengerAvailable
          puts "Regular ship probability grid:"
          print_probability_grid(probability_grid_regular)
        else
          puts "Irregular ship probability grid:"
          print_probability_grid(probability_grid_irregular)
        end
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
end

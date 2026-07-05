# can serve as a benchmark for the worst case scenario
require_relative '../map_generator.rb'
require_relative '../helpers/print_helpers.rb'
require_relative '../helpers/algo_helpers.rb'
require_relative '../constants.rb'
require_relative '../battleship_api_mock.rb'

require 'byebug'

module BruteForce
  include PrintHelpers
  include Constants

  module_function

  def brute_force(api)
    (0..(Constants::GRID_SIZE - 1)).each do |row|
      (0..(Constants::GRID_SIZE - 1)).each do |column|
        response = api.fire(row, column)

        if AlgoHelpers.verbose
          puts "Response: #{response}"
          puts response["cell"] == 'X' ? "Hit at #{row}, #{column}" : "Miss at #{row}, #{column}"
        end

        if response["finished"]
          if AlgoHelpers.verbose
            puts "Game over in #{response["moveCount"]} moves"
            api.print_grid(response["grid"])
          end
          return
        end
      end
    end
  end
end

require_relative 'map_generator.rb'
require_relative 'helpers.rb'
require_relative 'constants.rb'
require_relative 'battleship_api_mock.rb'

require 'byebug'

module Algos
  include Helpers
  include Constants

  module_function

  def brute_force(api)
    (0..(Constants::GRID_SIZE - 1)).each do |row|
      (0..(Constants::GRID_SIZE - 1)).each do |column|
        response = api.fire(row, column)
        puts "Response: #{response}"

        if response["result"]
          puts "Hit at #{row}, #{column}"
          api.print_grid(response["grid"])
        else
          puts "Miss at #{row}, #{column}"
        end

        if response["finished"]
          puts "Game over in #{response["moveCount"]} moves"
          api.print_grid(response["grid"])
          return
        end
      end
    end
  end
end

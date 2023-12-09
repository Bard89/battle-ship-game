require 'httparty'
require 'byebug'

# beautify responses
require 'awesome_print'
require 'json'

require_relative 'helpers.rb'
require_relative 'config.rb'

class TestBattleshipGame
  include HTTParty
  include Helpers

  base_uri 'europe-west1-ca-2023-dev.cloudfunctions.net/battleshipsApi'

  # attr_reader :options

  def initialize(config = {})
    @options = { headers: { 'Authorization' => "Bearer #{config['user_token']}" } }
  end

  def test_fire(row, column)
    self.class.get("/fire/#{row}/#{column}?test=yes", @options)
  end

  def test_reset
    self.class.get('/reset?test=yes', @options)
  end

  def test_fire_with_avenger(row, column, avenger)
    self.class.get("/fire/#{row}/#{column}/avenger/#{avenger}?test=yes", @options)
  end

  # don't use you will waste your api call (200)
  # plus you have it in a separate module
#   def brute_force
#     (0..11).each do |row|
#       (0..11).each do |column|
#         response = test_fire(row, column)
#         if response.parsed_response["result"]
#           puts "Hit at #{row}, #{column}"
#           print_grid(response.parsed_response["grid"])
#         end
#       end
#     end
#   end
end

game = TestBattleshipGame.new($config)
byebug
# response = game.test_fire(6, 7) # Replace with actual row, column, and avenger name


# to see the response in a nice format
ap response.parsed_response
# to see the current state of the grid
game.print_grid(response.parsed_response["grid"])


# game.brute_force

# reset_response = game.test_reset
# puts "Reset Response: #{reset_response}"

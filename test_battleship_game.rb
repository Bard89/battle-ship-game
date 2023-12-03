require 'httparty'
require 'byebug'
require_relative 'config.rb'

class TestBattleshipGame
  include HTTParty

  base_uri 'europe-west1-ca-2023-dev.cloudfunctions.net/battleshipsApi'

  def initialize(config = {})
    @options = { headers: { 'Authorization' => "Bearer #{config['user_token']}" } }
  end

  def test_fire(row, column)
    self.class.get("/fire/#{row}/#{column}?test=yes", @options)
  end

  def test_reset
    self.class.get('/reset?test=yes', @options)
  end

  def print_grid(grid_string)
    grid_string.chars.each_slice(12).with_index do |row, index|
      formatted_row_number = format('Row %-3d:', index) # Adjusts the spacing for row numbers
      puts "#{formatted_row_number} #{row.join(' ')}"
    end
  end

  def brute_force
    (0..11).each do |row|
      (0..11).each do |column|
        response = test_fire(row, column)
        if response.parsed_response["result"]
          puts "Hit at #{row}, #{column}"
          print_grid(response.parsed_response["grid"])
        end
      end
    end
  end
end

game = TestBattleshipGame.new($config)

response = game.test_fire(6, 7) # Replace with actual row, column, and avenger name
game.print_grid(response.parsed_response["grid"])
game.brute_force

# reset_response = game.test_reset
# puts "Reset Response: #{reset_response}"

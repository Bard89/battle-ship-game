require 'httparty'
require_relative 'config.rb'

class BattleshipGame
  include HTTParty
  base_uri 'europe-west1-ca-2023-dev.cloudfunctions.net/battleshipsApi'

  def initialize(config = {})
    @options = { headers: { 'Authorization' => "Bearer #{config['user_token']}" } }
  end

  def fire(row, column, avenger)
    self.class.get("/fire/#{row}/#{column}/avenger/#{avenger}", @options)
  end

  def test_fire(row, column)
    self.class.get("/fire/#{row}/#{column}?test=yes", @options)
  end

  def reset
    self.class.get('/reset', @options)
  end

  def test_reset
    self.class.get('/reset?test=yes', @options)
  end

end

game = BattleshipGame.new($config)

response = game.test_fire(5, 6) # Replace with actual row, column, and avenger name
puts "Fire Response: #{response}"

# reset_response = game.reset
# puts "Reset Response: #{reset_response}"

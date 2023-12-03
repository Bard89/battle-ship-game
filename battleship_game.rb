require 'httparty'
require 'byebug'
require_relative 'config.rb'

class BattleshipGame
  include HTTParty
  base_uri 'europe-west1-ca-2023-dev.cloudfunctions.net/battleshipsApi'

  def initialize(config = {})
    @options = { headers: { 'Authorization' => "Bearer #{config['user_token']}" } }
  end

  def fire(row, column)
    self.class.get("/fire/#{row}/#{column}", @options)
  end

  def reset
    self.class.get('/reset', @options)
  end
end

game = BattleshipGame.new($config)
byebug

response = game.fire(6, 7) # Replace with actual row, column, and avenger name
puts "Fire Response: #{response}"

reset_response = game.reset
puts "Reset Response: #{reset_response}"

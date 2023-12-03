require_relative 'battleship_api_mock.rb'
require_relative 'algos.rb'

api = MockBattleshipAPI.new
Algos.brute_force(api)

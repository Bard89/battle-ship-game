require_relative 'battleship_api_mock.rb'
require_relative 'algos/brute_force.rb'
require_relative 'algos/hunt_and_target.rb'
require_relative 'algos/probability_density.rb'

# api = MockBattleshipAPI.new
# Algos.brute_force(api)
# Algos.hunt_and_target(api)


def run_algorithm(algorithm, runs)
  total_moves = 0

  runs.times do
    api = MockBattleshipAPI.new
    algorithm.call(api)
    total_moves += api.move_count
  end

  total_moves.to_f / runs
end

runs = 10

avg_moves_brute_force = run_algorithm(BruteForce.method(:brute_force), runs)
avg_moves_hunt_and_target = run_algorithm(HuntAndTarget.method(:hunt_and_target), runs)
avg_moves_probability_density = run_algorithm(ProbabilityDensity.method(:probability_density), runs)

puts "Average moves (Brute Force): #{avg_moves_brute_force}"
puts "Average moves (Hunt and Target): #{avg_moves_hunt_and_target}"
puts "Average moves (Probability Density): #{avg_moves_probability_density}"


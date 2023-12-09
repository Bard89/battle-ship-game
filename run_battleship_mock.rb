require_relative 'battleship_api_mock.rb'
require_relative 'algos/brute_force.rb'
require_relative 'algos/hunt_and_target.rb'
require_relative 'algos/probability_density.rb'

require_relative 'constants.rb'

# api = MockBattleshipAPI.new
# Algos.brute_force(api)
# Algos.hunt_and_target(api)


def run_algorithm(algorithm, runs)
  total_moves = 0
  total_time = 0

  runs.times do
    api = MockBattleshipAPI.new

    start_time = Time.now
    algorithm.call(api)
    end_time = Time.now

    total_moves += api.move_count
    total_time += end_time - start_time
  end

  average_moves = total_moves.to_f / runs
  average_time = total_time / runs

  [total_moves, average_moves, average_time, total_time]
end

runs = 3

# avg_moves_brute_force = run_algorithm(BruteForce.method(:brute_force), runs)
# avg_moves_hunt_and_target = run_algorithm(HuntAndTarget.method(:hunt_and_target), runs)
total_moves_probability_density, avg_moves_probability_density, time_probability_density, total_time_probability_density = run_algorithm(ProbabilityDensity.method(:probability_density), runs)
# puts "Average moves (Brute Force): #{avg_moves_brute_force}"
# puts "Average moves (Hunt and Target): #{avg_moves_hunt_and_target}"
# puts "Average moves, average time, total time (Probability Density): #{avg_moves_probability_density}"

puts
puts "**Algo: Probability Density**"
puts "Total moves standardised for 200 games: #{(total_moves_probability_density / runs ) * 200}"
puts "current best is #{Constants::CURRENT_BEST_200_GAMES_RUN}"
puts "To beat the best you need to get #{(total_moves_probability_density / runs ) * 200 - Constants::CURRENT_BEST_200_GAMES_RUN} less moves"
puts "To beat the best you need to improve your algo by #{-((Constants::CURRENT_BEST_200_GAMES_RUN - (total_moves_probability_density / runs ) * 200) / Constants::CURRENT_BEST_200_GAMES_RUN.to_f).round(1) * 100}%"

puts "-----------------------------------------------------------"
puts "Total moves: #{total_moves_probability_density}"
puts "Average moves: #{avg_moves_probability_density}"
puts "Average time: #{'%.2f' % (time_probability_density * 1000)} milliseconds"
puts "Total Time: #{'%.2f' % (total_time_probability_density * 1000)} milliseconds or #{'%.2f' % time_probability_density} seconds"



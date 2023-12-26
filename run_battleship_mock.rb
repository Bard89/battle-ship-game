require_relative 'battleship_api_mock.rb'
require_relative 'algos/brute_force.rb'
require_relative 'algos/hunt_and_target.rb'
require_relative 'algos/probability_density.rb'
require_relative 'algos/modified_probability_density/modified_probability_density.rb'
require_relative 'helpers/algo_helpers.rb'
require_relative 'constants.rb'

def run_algorithm(algorithm, runs)
  total_moves = 0
  total_time = 0

  runs.times do
    api = BattleshipAPIMock.new

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

# in the end change this to 200 runs to simulate the real game
runs = 1

# total_moves_brute_force, avg_moves_brute_force, time_brute_force, total_time_brute_force = run_algorithm(BruteForce.method(:brute_force), runs)
# total_moves_hunt_and_target, avg_moves_hunt_and_target, time_hunt_and_target, total_time_hunt_and_target = run_algorithm(HuntAndTarget.method(:hunt_and_target), runs)
# total_moves_probability_density, avg_moves_probability_density, time_probability_density, total_time_probability_density = run_algorithm(ProbabilityDensity.method(:probability_density), runs)
total_moves_modified_probability_density, avg_moves_modified_probability_density, time_modified_probability_density, total_time_modified_probability_density = run_algorithm(ModifiedProbabilityDensity.method(:probability_density), runs)


# Display stats for each algorithm
def display_stats(algo_name, total_moves, avg_moves, avg_time, total_time, runs)
  puts
  puts "**Algo: #{algo_name}**"
  puts
  puts "Total moves standardised for 200 games: #{(total_moves / runs) * 200}"
  puts "You are percentage wise below the possible worst case by: #{((12 * 12 * 200 - (total_moves / runs) * 200) / (12 * 12 * 200).to_f * 100).round(1)}%"
  puts "The global current best is #{Constants::CURRENT_BEST_200_GAMES_RUN}"
  puts
  improvement_needed = (total_moves / runs) * 200 - Constants::CURRENT_BEST_200_GAMES_RUN
  puts "To beat the best you need to get #{improvement_needed} less moves by: #{(improvement_needed / Constants::CURRENT_BEST_200_GAMES_RUN.to_f * 100).round(1)}%"
  improvement_percent = -((Constants::CURRENT_BEST_200_GAMES_RUN - (total_moves / runs) * 200) / Constants::CURRENT_BEST_200_GAMES_RUN.to_f).round(1) * 100
  puts "To beat the best you need to improve your algo by #{improvement_percent.round(1)}%"
  puts
  puts "The probability density expected outcome without avengers is approx 12000.          (maybe a bit more because this is with confirmation of sunk ships, which we don't have)"
  puts "To match probability density expected outcome without avengers you need to get #{-(12000 - (total_moves / runs) * 200).round(1)} less moves by: #{-((12000 - (total_moves / runs) * 200) / 12000.to_f * 100).round(1)}%"
  puts "-----------------------------------------------------------"
  puts "Total moves: #{total_moves}"
  puts "Average moves: #{avg_moves}"
  puts "Average time: #{'%.2f' % (avg_time * 1000)} milliseconds"
  puts "Total Time: #{'%.2f' % (total_time * 1000)} milliseconds or #{'%.2f' % avg_time} seconds"
  puts
  puts
end

# display_stats("BRUTE FORCE", total_moves_brute_force, avg_moves_brute_force, time_brute_force, total_time_brute_force, runs)
# display_stats("Hunt and Target", total_moves_hunt_and_target, avg_moves_hunt_and_target, time_hunt_and_target, total_time_hunt_and_target, runs)
# display_stats("PROBABILITY DENSITY", total_moves_probability_density, avg_moves_probability_density, time_probability_density, total_time_probability_density, runs)
display_stats("MODIFIED PROBABILITY DENSITY", total_moves_modified_probability_density, avg_moves_modified_probability_density, time_modified_probability_density, total_time_modified_probability_density, runs)

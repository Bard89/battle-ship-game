# Benchmark runner for the battleship solvers.
#
#   ruby run_battleship_mock.rb [algo] [runs] [--seed N] [--verbose] [--sequential]
#
#   algo        constraint_solver (default), modified_probability_density,
#               probability_density, hunt_and_target, brute_force, or all
#   runs        number of games, default 200 (the real challenge plays 200 maps;
#               the summed move count of a 200-game run IS the challenge score)
#   --seed N    base seed for the map set, default 42; runs with the same seed
#               and count play identical maps, so algorithms compare fairly
#   --verbose   play a single game with all debug printouts (forces runs=1)
#   --sequential  disable parallel processing (parallel is default when quiet)
require_relative 'battleship_api_mock.rb'
require_relative 'algos/brute_force.rb'
require_relative 'algos/hunt_and_target.rb'
require_relative 'algos/probability_density.rb'
require_relative 'algos/modified_probability_density/modified_probability_density.rb'
require_relative 'algos/constraint_solver.rb'
require_relative 'helpers/algo_helpers.rb'
require_relative 'constants.rb'

require 'parallel'

ALGORITHMS = {
  'brute_force' => BruteForce.method(:brute_force),
  'hunt_and_target' => HuntAndTarget.method(:hunt_and_target),
  'probability_density' => ProbabilityDensity.method(:probability_density),
  'modified_probability_density' => ModifiedProbabilityDensity.method(:probability_density),
  'constraint_solver' => ConstraintSolver.method(:solve)
}.freeze

def run_games(algorithm, runs, seed_base, parallel)
  play = lambda do |i|
    api = BattleshipAPIMock.new(seed: seed_base + i, verbose: AlgoHelpers.verbose)
    algorithm.call(api)
    api.move_count
  end

  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  moves = if parallel
            Parallel.map(1..runs, in_processes: Parallel.processor_count) { |i| play.call(i) }
          else
            (1..runs).map { |i| play.call(i) }
          end
  [moves, Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at]
end

def display_stats(algo_name, moves, total_time, runs)
  total = moves.sum
  average = total.to_f / runs
  sorted = moves.sort
  variance = moves.sum { |m| (m - average)**2 } / runs
  score200 = (average * 200).round

  puts "\n**#{algo_name}** (#{runs} games)"
  puts format('Total moves: %d | avg %.2f | median %d | min %d | max %d | std %.1f',
              total, average, sorted[runs / 2], sorted.first, sorted.last, Math.sqrt(variance))
  puts format('Score for 200 games: %d (challenge leaderboard best: %d)',
              score200, Constants::CURRENT_BEST_200_GAMES_RUN)
  gap = score200 - Constants::CURRENT_BEST_200_GAMES_RUN
  comparison = gap.positive? ? format('%d moves (%.1f%%) above', gap, 100.0 * gap / Constants::CURRENT_BEST_200_GAMES_RUN) : format('%d moves below', -gap)
  puts "That is #{comparison} the all-time leaderboard best."
  puts format('Time: %.2fs total, %.1fms per game', total_time, total_time / runs * 1000)
end

args = ARGV.dup
verbose = !args.delete('--verbose').nil?
sequential = !args.delete('--sequential').nil?
seed_base = 42
if (seed_index = args.index('--seed'))
  seed_base = Integer(args[seed_index + 1])
  args.slice!(seed_index, 2)
end
algo_arg = args.find { |arg| !arg.match?(/\A\d+\z/) } || 'constraint_solver'
runs = (args.find { |arg| arg.match?(/\A\d+\z/) } || 200).to_i
if verbose
  AlgoHelpers.verbose = true
  runs = 1
  sequential = true
end

selected = algo_arg == 'all' ? ALGORITHMS.keys : [algo_arg]
unless (unknown = selected - ALGORITHMS.keys).empty?
  abort "Unknown algorithm #{unknown.first}. Available: #{ALGORITHMS.keys.join(', ')}, all"
end

selected.each do |name|
  moves, time = run_games(ALGORITHMS[name], runs, seed_base, !sequential)
  display_stats(name, moves, time, runs)
end

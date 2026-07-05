# Runner for the battleship solvers: watch a game being played, or benchmark.
#
#   ruby run_battleship_mock.rb [algo] [runs] [--seed N] [--delay S] [--verbose] [--sequential]
#
# WATCH MODE (default when no runs count is given): plays ONE game visually -
# shows the generated map, every shot on the board, the probability field the
# shot was chosen from, and the stats at the end.
#
#   ruby run_battleship_mock.rb                              watch the constraint solver
#   ruby run_battleship_mock.rb modified_probability_density watch the old algo
#   ruby run_battleship_mock.rb --delay 0.5 --seed 7         slower, specific map
#
# BENCHMARK MODE (a runs count is given): quiet parallel run with stats.
#
#   ruby run_battleship_mock.rb constraint_solver 200        the challenge score
#   ruby run_battleship_mock.rb all 200                      compare all algorithms
#
#   algo        constraint_solver (default), modified_probability_density,
#               probability_density, hunt_and_target, brute_force, or all
#   runs        number of games (the real challenge plays 200 maps; the summed
#               move count of a 200-game run IS the challenge score)
#   --seed N    base seed for the map set, default 42; runs with the same seed
#               and count play identical maps, so algorithms compare fairly
#   --delay S   seconds between moves in watch mode, default 0.15
#   --verbose   force watch mode even when a runs count is given (plays 1 game)
#   --sequential  disable parallel processing in benchmark mode
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

USAGE = 'Usage: ruby run_battleship_mock.rb [algo|all] [runs] [--seed N] [--delay S] [--verbose] [--sequential]'.freeze

def take_flag_with_value(args, flag, pattern, error)
  if (equals_form = args.find { |arg| arg.start_with?("#{flag}=") })
    args.delete(equals_form)
    args.push(flag, equals_form.delete_prefix("#{flag}="))
  end
  return nil unless (index = args.index(flag))

  value = args[index + 1]
  abort "#{error}\n#{USAGE}" unless value&.match?(pattern)

  args.slice!(index, 2)
  value
end

args = ARGV.dup
verbose = !args.delete('--verbose').nil?
sequential = !args.delete('--sequential').nil?
# fixed default seed so runs are reproducible; pass other seeds for fresh map sets
seed_base = (take_flag_with_value(args, '--seed', /\A-?\d+\z/, '--seed needs an integer value.') || 42).to_i
delay = take_flag_with_value(args, '--delay', /\A\d+(\.\d+)?\z/, '--delay needs a non-negative number of seconds.')&.to_f
if (unknown_flag = args.find { |arg| arg.start_with?('--') })
  abort "Unknown option #{unknown_flag}.\n#{USAGE}"
end

algo_arg = args.find { |arg| !arg.match?(/\A\d+\z/) } || 'constraint_solver'
runs_arg = args.find { |arg| arg.match?(/\A\d+\z/) }

# no runs count = watch mode: one visual game, like the project always played
watch = verbose || runs_arg.nil?
runs = watch ? 1 : runs_arg.to_i
abort "runs must be at least 1.\n#{USAGE}" if runs < 1
if watch
  AlgoHelpers.verbose = true
  AlgoHelpers.watch_delay = delay || 0.15
  sequential = true
end

selected = algo_arg == 'all' ? ALGORITHMS.keys : [algo_arg]
unless (unknown = selected - ALGORITHMS.keys).empty?
  abort "Unknown algorithm #{unknown.first}. Available: #{ALGORITHMS.keys.join(', ')}, all\n#{USAGE}"
end

selected.each do |name|
  moves, time = run_games(ALGORITHMS[name], runs, seed_base, !sequential)
  display_stats(name, moves, time, runs)
end

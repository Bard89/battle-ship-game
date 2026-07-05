module Constants
  GRID_SIZE = 12

  # Official fleet per the challenge rules (see the Coding Arena HTML copy):
  # Avengers Helicarrier (9), Carrier (5), Battleship (4), Destroyer (3),
  # Submarine (3), Patrol Boat (2) -> 6 ships, 26 ship cells in total.
  REGULAR_SHIPS = [5, 4, 3, 3, 2]
  REGULAR_SHIP_SHAPES = REGULAR_SHIPS.map { |size| [Array.new(size, 'S')] }

  # the I is better than just S so we can match the ship and return that we have avengers available
  IRREGULAR_SHIP_HORIZONTAL = [
    %w[* I * I *],
    %w[I I I I I],
    %w[* I * I *]
  ]
  IRREGULAR_SHIP_VERTICAL = IRREGULAR_SHIP_HORIZONTAL.transpose
  IRREGULAR_SHIP_SIZE = IRREGULAR_SHIP_HORIZONTAL.flatten.count('I')

  TOTAL_SHIP_CELLS = REGULAR_SHIPS.sum + IRREGULAR_SHIP_SIZE

  # game stats
  CURRENT_BEST_200_GAMES_RUN = 9625 # final leaderboard best of the 2023 challenge

  # kind of superpowers one can get after sinking the irregular ship
  AVENGERS = %w[hulk ironman thor]
  THOR_EXTRA_POINTS = 10 # thor reveals up to 10 random untouched points on top of the fired one

  # probability changes for the legacy probability_density algos
  IRREGULAR_SHIP_POSITION_PROBABILITY_INCREMENT = 0.2
  REGULAR_SHIP_POSITION_PROBABILITY_INCREMENT = 0.4

  SHIP_PLACEMENT_PROBABILITY_DECREMENT = 0.2

  ADJACENT_CELL_PROBABILITY_INCREMENT = 0.1
  ADJACENT_CELL_PROBABILITY_DECREMENT = 0.1

  SHIP_PATTERN_PROBABILITY_INCREMENT = 3.5
end

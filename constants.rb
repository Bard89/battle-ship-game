module Constants
  GRID_SIZE = 12

  REGULAR_SHIPS = [4, 3, 3, 2]
  REGULAR_SHIP_SHAPES = [
    [%w[S S S S]],
    [%w[S S S]],
    [%w[S S S]],
    [%w[S S]]
  ]

  # the I is better than just S so we can match the ship and return that we have avengers available
  IRREGULAR_SHIP_HORIZONTAL = [
    %w[* I * I *],
    %w[I I I I I],
    %w[* I * I *]
  ]
  IRREGULAR_SHIP_VERTICAL = IRREGULAR_SHIP_HORIZONTAL.transpose

  # game stats
  CURRENT_BEST_200_GAMES_RUN = 9625 # check periodically on https://www.panaxeo.com/coding-arena#api

  # kind of superpowers one can get after sinking the irregular ship
  AVENGERS = %w[hulk, ironman, thor]

  # probability changes for the probability_density algo
  IRREGULAR_SHIP_POSITION_PROBABILITY_INCREMENT = 0.2
  REGULAR_SHIP_POSITION_PROBABILITY_INCREMENT = 0.4

  SHIP_PLACEMENT_PROBABILITY_DECREMENT = 0.2

  ADJACENT_CELL_PROBABILITY_INCREMENT = 0.1
  ADJACENT_CELL_PROBABILITY_DECREMENT = 0.1

  SHIP_PATTERN_PROBABILITY_INCREMENT = 3.5
end

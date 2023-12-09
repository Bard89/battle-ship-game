module Constants
  GRID_SIZE = 12
  REGULAR_SHIPS = [4, 3, 3, 2] # Regular ships
  IRREGULAR_SHIP_HORIZONTAL = [
    %w[* S * S *],
    %w[S S S S S],
    %w[* S * S *]
  ]
  IRREGULAR_SHIP_VERTICAL = IRREGULAR_SHIP_HORIZONTAL.transpose
  CURRENT_BEST_200_GAMES_RUN = 9657 # check periodically on https://www.panaxeo.com/coding-arena#api
  AVENGERS = %w[hulk, ironman, thor]
end

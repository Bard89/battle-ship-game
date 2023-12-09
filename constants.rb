module Constants
  GRID_SIZE = 12
  REGULAR_SHIPS = [4, 3, 3, 2] # Regular ships
  IRREGULAR_SHIP_HORIZONTAL = [
    %w[* S * S *],
    %w[S S S S S],
    %w[* S * S *]
  ]
  IRREGULAR_SHIP_VERTICAL = IRREGULAR_SHIP_HORIZONTAL.transpose
  AVENGERS = %w[hulk, ironman, thor]
end

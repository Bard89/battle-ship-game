# This module is responsible for tracking ship hits and determining if ships have been sunk in the game of Battleship.
# It manages both regular and irregular ships, updating the probability grid based on hits and sunken ships.
module ShipSunkOrNotProbability

  # Initializes the tracking of hits on ships. It sets up a hash to track hits on ships and an array to keep track of confirmed sunk ships.
  def initialize_ship_tracking
    @hit_ships = {} # Hash to track hits on ships, with each ship's hits stored as an array of coordinates.
    @confirmed_sunk_ships = [] # Array to keep track of confirmed sunk ships.
  end

  # Updates the ship sinking status based on the latest hit.
  # @param probability_grid [Array] The current probability grid of the game.
  # @param target_row [Integer] The row index of the target cell.
  # @param target_col [Integer] The column index of the target cell.
  # @param result [Boolean] The result of the hit attempt (true if hit, false otherwise).
  def update_ship_sunk_or_not(probability_grid, target_row, target_col, result)
    if result
      ship_hits = record_hit(target_row, target_col)

      if ship_sunk?(ship_hits, probability_grid)
        update_for_sunk_ship(ship_hits, probability_grid)

        @confirmed_sunk_ships.concat(ship_hits)
        @hit_ships.delete(ship_hits.object_id)
      end
    end
  end

  # Records a hit on a ship and checks if it connects to an existing ship.
  # @param row [Integer] The row index of the hit cell.
  # @param col [Integer] The column index of the hit cell.
  # @return [Array] An array of hit coordinates for a particular ship.
  def record_hit(row, col)
    @hit_ships.each do |hits|
      if hits.any? { |hit_row, hit_col| adjacent?(hit_row, hit_col, row, col) }
        hits << [row, col]
        return hits
      end
    end
    new_ship_hits = [[row, col]]
    @hit_ships[new_ship_hits.object_id] = new_ship_hits
    new_ship_hits
  end

  # Checks if two cells are adjacent (excluding diagonals).
  # @param row1 [Integer] Row index of the first cell.
  # @param col1 [Integer] Column index of the first cell.
  # @param row2 [Integer] Row index of the second cell.
  # @param col2 [Integer] Column index of the second cell.
  # @return [Boolean] True if cells are adjacent, false otherwise.
  def adjacent?(row1, col1, row2, col2)
    (row1 == row2 && (col1 - col2).abs == 1) || (col1 == col2 && (row1 - row2).abs == 1)
  end

  # Determines if a ship is sunk based on the current hits.
  # @param ship_hits [Array] An array of hit coordinates for a ship.
  # @param probability_grid [Array] The current probability grid of the game.
  # @return [Boolean] True if the ship is sunk, false otherwise.
  def ship_sunk?(ship_hits, probability_grid)
    ship_hits.all? do |hit_row, hit_col|
      adjacent_cells(hit_row, hit_col).all? do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] == 0 || @confirmed_sunk_ships.include?([adj_row, adj_col])
      end
    end
  end

  # Retrieves a list of adjacent cells for a given cell.
  # @param row [Integer] The row index of the cell.
  # @param col [Integer] The column index of the cell.
  # @return [Array] An array of adjacent cell coordinates.
  def adjacent_cells(row, col)
    [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]].select do |adj_row, adj_col|
      valid_coordinates?(adj_row, adj_col)
    end
  end

  # Updates the probability grid when a ship is sunk.
  # @param ship_hits [Array] An array of hit coordinates for the sunk ship.
  # @param probability_grid [Array] The current probability grid of the game.
  def update_for_sunk_ship(ship_hits, probability_grid)
    ship_hits.each do |hit_row, hit_col|
      probability_grid[hit_row][hit_col] = 0
      adjacent_cells(hit_row, hit_col).each do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] = 0 unless @confirmed_sunk_ships.include?([adj_row, adj_col])
      end
    end
  end
end

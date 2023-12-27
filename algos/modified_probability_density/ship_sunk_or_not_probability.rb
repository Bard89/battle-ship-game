require_relative '../../constants.rb'

module ShipSunkOrNotProbability
  def initialize_ship_tracking
    @hit_ships = []
    @confirmed_sunk_ships = []
  end

  # Updates the ship sunk status based on the latest firing result.
  # @param probability_grid [Array<Array>] The probability grid.
  # @param target_row [Integer] Row index of the target.
  # @param target_col [Integer] Column index of the target.
  # @param result [Boolean] True if the shot was a hit, false otherwise.
  def update_ship_sunk_or_not(probability_grid, target_row, target_col, result)
    byebug
    if result
      ship_hits = record_hit(target_row, target_col)

      if ship_sunk?(ship_hits, probability_grid)
        update_for_sunk_ship(ship_hits, probability_grid)
        @confirmed_sunk_ships.concat(ship_hits)
        @hit_ships.delete(ship_hits.object_id)
      end
    end
  end

  # Records a hit and updates ship hit tracking.
  # @param row [Integer] Row index of the hit.
  # @param col [Integer] Column index of the hit.
  def record_hit(row, col)
    hit_added = false

    @hit_ships.each do |hits|
      hits.each do |hit_row, hit_col|
        if adjacent?(hit_row, hit_col, row, col)
          hits << [row, col]
          hit_added = true
          break
        end
      end
      break if hit_added
    end

    @hit_ships << [[row, col]] unless hit_added
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

  # Determines if a ship is sunk based on recorded hits.
  # @param ship_hits [Array<Array>] The coordinates of the hits on the ship.
  # @param probability_grid [Array<Array>] The probability grid.
  # @return [Boolean] True if the ship is sunk, false otherwise.
  def ship_sunk?(ship_hits, probability_grid)
    ship_hits.all? do |hit|
      hit_row, hit_col = hit[0], hit[1]
      adjacent_cells(hit_row, hit_col).all? do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] == 'X' || probability_grid[adj_row][adj_col] == '*'
      end
    end
  end

  # Updates the probability grid for a sunk ship.
  # @param ship_hits [Array<Array>] The coordinates of the hits on the ship.
  # @param probability_grid [Array<Array>] The probability grid.
  def update_for_sunk_ship(ship_hits, probability_grid)
    ship_hits.each do |hit_row, hit_col|
      probability_grid[hit_row][hit_col] = 0
      adjacent_cells(hit_row, hit_col).each do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] = 0 unless @confirmed_sunk_ships.include?([adj_row, adj_col])
      end
    end
    hit_ship_key = @hit_ships.key(ship_hits)
    @hit_ships.delete(hit_ship_key) if hit_ship_key
  end

  # Gets adjacent cells of a given cell, excluding diagonals.
  # @param row [Integer] Row index of the cell.
  # @param col [Integer] Column index of the cell.
  # @return [Array<Array>] List of adjacent cells.
  def adjacent_cells(row, col)
    [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]].select do |adj_row, adj_col|
      valid_coordinates?(adj_row, adj_col)
    end
  end
end

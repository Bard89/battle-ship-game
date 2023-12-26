require_relative '../../constants.rb'

module ShipSunkOrNotProbability
  # Determine if the ship is sunk
  def ship_sunk?(ship_hits, probability_grid)
    ship_hits.all? do |hit_row, hit_col|
      # If all adjacent cells are either hit or have a probability of 0, the ship is considered sunk
      adjacent_cells(hit_row, hit_col).all? do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] == 0 || @confirmed_sunk_ships.include?([adj_row, adj_col])
      end
    end
  end

  # Get a list of adjacent cells
  def adjacent_cells(row, col)
    [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]].select do |adj_row, adj_col|
      valid_coordinates?(adj_row, adj_col)
    end
  end

  # Method to update the probability grid for a sunk ship
  def update_for_sunk_ship(ship_hits, probability_grid)
    ship_hits.each do |hit_row, hit_col|
      # Set the probability of the hit cells to 0
      probability_grid[hit_row][hit_col] = 0
      # Also set the probability of the adjacent cells to 0
      adjacent_cells(hit_row, hit_col).each do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] = 0 unless @confirmed_sunk_ships.include?([adj_row, adj_col])
      end
    end
  end
end

# Module ShipSunkOrNotProbability provides functionality to track and update the status of ships.
# It includes methods for recording hits on ships, determining if a ship
# is sunk, and updating probability grids accordingly.
module ShipSunkOrNotProbability
  # Initializes tracking structures for hit ships and confirmed sunk ships.
  # @partially_sunk_ships stores coordinates of hits with the key being the ship size (or nil if size is unknown).
  # @fully_sunk_ships stores coordinates of sunk ships, including special 'irregular' ships.
  def initialize_ship_tracking
    @partially_sunk_ships = {} # Key: Ship size or nil, Value: Array of hit coordinates
    @fully_sunk_ships = {} # Tracks sunk ships by size
  end

  # Updates the sunk status of ships after each hit. It checks if the hit results in any ship being sunk.
  def update_ship_sunk_or_not(probability_grid, target_row, target_col, result, api)
    return unless result


    ship_hits, ship_size = record_hit(target_row, target_col)

    if ship_sunk?(ship_hits, probability_grid)
      ship_size = ship_size.nil? ? infer_ship_size(ship_hits) : ship_size
      update_for_sunk_ship(ship_hits, ship_size, probability_grid)
      @fully_sunk_ships[ship_size] = ship_hits
      @partially_sunk_ships.delete(ship_size)
      puts "Ship sunk: #{ship_size}"
    end

    process_irregular_ship(api)
  end

  def process_irregular_ship(api)
    return if !api.avengerAvailable || @fully_sunk_ships['irregular']

    @fully_sunk_ships[9] = true
    @partially_sunk_ships.delete(9)
  end

  # Records a hit at the specified coordinates and associates it with a ship.
  def record_hit(new_hit_row, new_hit_col)
    return if @partially_sunk_ships.any? { |_, hits| hits.include?([new_hit_row, new_hit_col]) }

    # Check if the hit connects to an existing ship
    @partially_sunk_ships.each do |size, hits|
      if hits.any? { |already_hit_row, already_hit_col| cells_adjacent?(already_hit_row, already_hit_col, new_hit_row, new_hit_col) }
        hits << [new_hit_row, new_hit_col]

        return [hits, size]
      end
    end

    # Start tracking a new ship if it's a new hit
    @partially_sunk_ships[nil] ||= []
    @partially_sunk_ships[nil] << [new_hit_row, new_hit_col]
    [@partially_sunk_ships[nil], nil]
  end

  # Checks if two cells are adjacent based on their coordinates.
  # @return [Boolean] True if cells are adjacent, false otherwise.
  def cells_adjacent?(already_hit_row, already_hit_col, new_hit_row, new_hit_col)
    (already_hit_row == new_hit_row && (already_hit_col - new_hit_col).abs == 1) || (already_hit_col == new_hit_col && (already_hit_row - new_hit_row).abs == 1)
  end

  # Determines if a ship is sunk based on the pattern of hits and surrounding cells.
  # @param ship_hits [Array<Array<Integer>>] Coordinates of hits on the ship.
  # @param probability_grid [Array<Array<Integer>>] The grid representing probability values for each cell.
  # @return [Boolean] True if the ship is sunk, false otherwise.
  def ship_sunk?(ship_hits, probability_grid)
    return false if ship_hits.nil? || ship_hits.empty?

    inferred_size = infer_ship_size(ship_hits)
    return false if ship_hits.uniq.size != inferred_size

    ship_hits.sort_by { |hit| [hit[0], hit[1]] }.each_cons(2) do |hit1, hit2|
      next unless (hit1[0] == hit2[0] && (hit1[1] - hit2[1]).abs == 1) ||
        (hit1[1] == hit2[1] && (hit1[0] - hit2[0]).abs == 1)

      return false unless surrounding_cells_sunk_or_missed(hit1, hit2, probability_grid)
    end

    true
  end

  # Checks if the surrounding cells of a ship are sunk or missed, aiding in determining if a ship is sunk.
  # @param hit1 [Array<Integer>] Coordinates of the first hit.
  # @param hit2 [Array<Integer>] Coordinates of the second hit.
  # @param probability_grid [Array<Array<Integer>>] The grid representing probability values for each cell.
  # @return [Boolean] True if surrounding cells are sunk or missed, false otherwise.
  def surrounding_cells_sunk_or_missed(hit1, hit2, probability_grid)
    row_range = [hit1[0], hit2[0]].min..[hit1[0], hit2[0]].max
    col_range = [hit1[1], hit2[1]].min..[hit1[1], hit2[1]].max

    row_range.each do |row|
      col_range.each do |col|
        next if [row, col] == hit1 || [row, col] == hit2
        return false unless probability_grid[row][col] == 0
      end
    end

    true
  end

  # Returns adjacent cells for a given cell on the grid.
  # @param row [Integer] The row coordinate of the cell.
  # @param col [Integer] The column coordinate of the cell.
  # @return [Array<Array<Integer>>] An array of adjacent cell coordinates.
  def adjacent_cells(row, col)
    [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]].select do |adj_row, adj_col|
      valid_coordinates?(adj_row, adj_col)
    end
  end

  # Updates the probability grid and tracking for a sunk ship.
  # @param ship_hits [Array<Array<Integer>>] Coordinates of hits on the ship.
  # @param ship_size [Integer] The size of the ship.
  # @param probability_grid [Array<Array<Integer>>] The grid representing probability values for each cell.
  def update_for_sunk_ship(ship_hits, ship_size, probability_grid)
    ship_hits.each do |hit_row, hit_col|
      probability_grid[hit_row][hit_col] = 0
      adjacent_cells(hit_row, hit_col).each do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] = 0 unless @fully_sunk_ships.values.flatten(1).include?([adj_row, adj_col])
      end
    end
    update_ship_size(ship_hits, ship_size) if ship_size.nil?
  end

  # Updates the ship size in the tracking once it's inferred.
  # @param ship_hits [Array<Array<Integer>>] Coordinates of hits on the ship.
  # @param ship_size [Integer] The inferred size of the ship.
  def update_ship_size(ship_hits, ship_size)
    @partially_sunk_ships[ship_size] = ship_hits
    @partially_sunk_ships.delete(nil)
  end

  # Infers the size of a ship based on the pattern of hits.
  # @param ship_hits [Array<Array<Integer>>] Coordinates of hits on the ship.
  # @return [Integer] The inferred size of the ship.
  def infer_ship_size(ship_hits)
    return 0 if ship_hits.nil? || ship_hits.empty?

    sorted_by_rows = ship_hits.sort_by { |hit| [hit[0], hit[1]] }
    sorted_by_cols = ship_hits.sort_by { |hit| [hit[1], hit[0]] }

    max_length_row = max_continuous_hits(sorted_by_rows)
    max_length_col = max_continuous_hits(sorted_by_cols)

    [max_length_row, max_length_col].max
  end

  # Calculates the maximum length of continuous hits in a sorted array of hits.
  # This is used for inferring the size of a ship.
  # @param sorted_hits [Array<Array<Integer>>] A sorted array of hit coordinates.
  # @return [Integer] The maximum length of continuous hits.
  def max_continuous_hits(sorted_hits)
    max_length = 1
    current_length = 1

    (1...sorted_hits.size).each do |i|
      if sorted_hits[i][0] == sorted_hits[i - 1][0] && (sorted_hits[i][1] - sorted_hits[i - 1][1]).abs == 1 ||
        sorted_hits[i][1] == sorted_hits[i - 1][1] && (sorted_hits[i][0] - sorted_hits[i - 1][0]).abs == 1
        current_length += 1
        max_length = [max_length, current_length].max
      else
        current_length = 1
      end
    end

    max_length
  end
end

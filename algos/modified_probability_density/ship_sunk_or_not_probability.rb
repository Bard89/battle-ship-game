module ShipSunkOrNotProbability

  def initialize_ship_tracking
    @hit_ships = {} # Key: Ship size or nil, Value: Array of hit coordinates
    @confirmed_sunk_ships = {} # Tracks sunk ships by size or 'irregular'
  end

  def update_ship_sunk_or_not(probability_grid, target_row, target_col, result, api)
    if result
      ship_hits, ship_size = record_hit(target_row, target_col)

      if ship_sunk?(ship_hits, probability_grid)
        ship_size = ship_size.nil? ? infer_ship_size(ship_hits) : ship_size
        update_for_sunk_ship(ship_hits, ship_size, probability_grid)

        @confirmed_sunk_ships[ship_size] = ship_hits
        @hit_ships.delete(ship_size)
        puts "Ship sunk: #{ship_size}"
      end
    end

    process_avenger_availability(api) if api.avengerAvailable
  end

  def record_hit(row, col)
    new_hit = [row, col]

    # Avoid adding a hit that's already been recorded
    return if @hit_ships.any? { |_, hits| hits.include?(new_hit) }

    # Check if the hit connects to an existing ship
    @hit_ships.each do |size, hits|
      if hits.any? { |hit_row, hit_col| adjacent?(hit_row, hit_col, row, col) }
        hits << new_hit
        return [hits, size]
      end
    end

    # Start tracking a new ship if it's a new hit
    @hit_ships[nil] ||= []
    @hit_ships[nil] << new_hit
    [@hit_ships[nil], nil]

    # Ensure that ship_hits is never nil
    ship_hits = @hit_ships.find { |_, hits| hits.include?([row, col]) }&.last
    ship_hits ||= [] # If ship_hits is nil, initialize it as an empty array
    ship_hits << [row, col] unless ship_hits.include?([row, col])

    [ship_hits, nil] # Return ship_hits and nil for ship_size as it's unknown yet
  end


  def adjacent?(row1, col1, row2, col2)
    (row1 == row2 && (col1 - col2).abs == 1) || (col1 == col2 && (row1 - row2).abs == 1)
  end

  def ship_sunk?(ship_hits, probability_grid)
    return false if ship_hits.nil? || ship_hits.empty?

    inferred_size = infer_ship_size(ship_hits)
    return false if ship_hits.uniq.size != inferred_size

    ship_hits.sort_by { |hit| [hit[0], hit[1]] }.each_cons(2) do |hit1, hit2|
      # Check if hits are adjacent and in the same row or column
      next unless (hit1[0] == hit2[0] && (hit1[1] - hit2[1]).abs == 1) ||
        (hit1[1] == hit2[1] && (hit1[0] - hit2[0]).abs == 1)

      # Check surrounding cells of the ship
      return false unless surrounding_cells_sunk_or_missed(hit1, hit2, probability_grid)
    end

    true
  end


  def surrounding_cells_sunk_or_missed(hit1, hit2, probability_grid)
    # Define the range of rows and columns to check based on hit positions
    row_range = [hit1[0], hit2[0]].min..[hit1[0], hit2[0]].max
    col_range = [hit1[1], hit2[1]].min..[hit1[1], hit2[1]].max

    row_range.each do |row|
      col_range.each do |col|
        next if [row, col] == hit1 || [row, col] == hit2 # Skip the hit cells
        return false unless probability_grid[row][col] == 0
      end
    end

    true
  end


  def adjacent_cells(row, col)
    [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]].select do |adj_row, adj_col|
      valid_coordinates?(adj_row, adj_col)
    end
  end

  def update_for_sunk_ship(ship_hits, ship_size, probability_grid)
    ship_hits.each do |hit_row, hit_col|
      probability_grid[hit_row][hit_col] = 0
      adjacent_cells(hit_row, hit_col).each do |adj_row, adj_col|
        probability_grid[adj_row][adj_col] = 0 unless @confirmed_sunk_ships.values.flatten(1).include?([adj_row, adj_col])
      end
    end
    update_ship_size(ship_hits, ship_size) if ship_size.nil?
  end

  def update_ship_size(ship_hits, ship_size)
    @hit_ships[ship_size] = ship_hits
    @hit_ships.delete(nil)
  end

  def process_avenger_availability(api)
    # Mark the irregular ship as sunk when Avenger is available
    @confirmed_sunk_ships['irregular'] = true
    @hit_ships.delete('irregular')
  end

  def infer_ship_size(ship_hits)
    return 0 if ship_hits.nil? || ship_hits.empty?

    sorted_by_rows = ship_hits.sort_by { |hit| [hit[0], hit[1]] }
    sorted_by_cols = ship_hits.sort_by { |hit| [hit[1], hit[0]] }

    max_length_row = max_continuous_hits(sorted_by_rows)
    max_length_col = max_continuous_hits(sorted_by_cols)

    [max_length_row, max_length_col].max
  end

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

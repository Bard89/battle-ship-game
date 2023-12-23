require_relative '../constants.rb'

module PrintHelpers
  def color_for_ship(cell)
    case cell
    when 'I' # Irregular ship
      "\e[31mI\e[0m" # Red
    when 'S' # Regular ship
      # red orange
      "\e[38;5;208mS\e[0m"
    when 'X' # shot
      # blue
      "\e[38;5;33mX\e[0m"
    else
      cell # No color for other cells
    end
  end

  def print_grid(grid_string)
    # Adding column headers (0 to 11) with spacing to match the grid
    column_headers = '        ' + (0...Constants::GRID_SIZE).map { |n| n.to_s.ljust(2) }.join(' ')
    puts column_headers

    # Printing each row with its row number
    grid_string.chars.each_slice(Constants::GRID_SIZE).with_index do |row, index|
      formatted_row_number = format('Row %-3d', index) # Adjusts the spacing for row numbers
      colored_row = row.map { |cell| color_for_ship(cell) }.join('  ') # Apply color to ships
      puts "#{formatted_row_number} #{colored_row}"
    end
  end

  def color_for_probability(prob, min_prob, max_prob)
    if prob < 0
      # Map negative probabilities to grayscale
      intensity = 232 + (255 - 232) * [prob / min_prob, 1].min # 232 to 255 are grayscale
      return "\e[38;5;#{intensity}m"
    end

    # Map non-negative probabilities to colors with red as highest
    ratio = (prob - min_prob) / (max_prob - min_prob)
    case ratio
    when 0.0..0.1
      "\e[38;5;40m"  # Dark Green
    when 0.1..0.2
      "\e[38;5;46m"  # Green
    when 0.2..0.3
      "\e[38;5;82m"  # Light Green
    when 0.3..0.4
      "\e[38;5;118m" # Green-Yellow
    when 0.4..0.5
      "\e[38;5;154m" # Yellow-Green
    when 0.5..0.6
      "\e[38;5;220m" # Yellow
    when 0.6..0.7
      "\e[38;5;214m" # Yellow-Orange
    when 0.7..0.8
      "\e[38;5;208m" # Orange
    when 0.8..0.9
      "\e[38;5;202m" # Red-Orange
    else
      "\e[38;5;196m" # Bright Red (Highest probability)
    end
  end

  def print_probability_grid(probability_grid)
    max_prob = probability_grid.flatten.max
    min_prob = probability_grid.flatten.min

    # Adjust the headers to be centered over 5 characters
    column_headers = ' ' * 9 + (0...Constants::GRID_SIZE).map { |n| n.to_s.center(5) }.join(' ')
    puts column_headers

    probability_grid.each_with_index do |row, index|
      formatted_row_number = format('Row %-3d', index) # Adjusts the spacing for row numbers
      formatted_row = row.map do |prob|
        formatted_prob = format("%+5.1f", prob) # Ensure the number takes up 5 spaces including the sign
        "#{color_for_probability(prob, min_prob, max_prob)}#{formatted_prob}\e[0m"
      end.join(' ')
      puts "#{formatted_row_number} #{formatted_row}"
    end
  end

  def self.color_for_probability(prob, max_prob)
    intensity = (prob.to_f / max_prob) ** 0.5  # Square root for better contrast
    [(intensity * 255).to_i, 0, (255 - intensity * 255).to_i, 1]  # RGB Alpha
  end

  def valid_coordinates?(row, column)
    row.between?(0, Constants::GRID_SIZE - 1) && column.between?(0, Constants::GRID_SIZE - 1)
  end
end

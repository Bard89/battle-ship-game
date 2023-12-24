require_relative '../constants.rb'

module PrintHelpers
  # grid with normal width
  # def print_grid(grid_string)
  #   # Adding column headers (0 to 11) with spacing to match the grid
  #   column_headers = '        ' + (0...Constants::GRID_SIZE).map { |n| n.to_s.ljust(2) }.join(' ')
  #   puts column_headers
  #
  #   # Printing each row with its row number
  #   grid_string.chars.each_slice(Constants::GRID_SIZE).with_index do |row, index|
  #     formatted_row_number = format('Row %-3d', index) # Adjusts the spacing for row numbers
  #     colored_row = row.map { |cell| colorize_ship(cell) }.join('  ') # Apply color to ships
  #     puts "#{formatted_row_number} #{colored_row}"
  #   end
  #   # otherwise it will return the nonformatted grid_string
  #   nil
  #   # uncomment to be able to debug the algo better
  #   sleep(0.3)
  # end

  # grid as wide as the probability grid
  def print_grid(grid_string)
    # Adjust the headers to be centered over 5 characters
    column_headers = ' ' * 9 + (0...Constants::GRID_SIZE).map { |n| n.to_s.center(5) }.join(' ')
    puts column_headers

    # Printing each row with its row number
    grid_string.chars.each_slice(Constants::GRID_SIZE).with_index do |row, index|
      formatted_row_number = format('Row %-3d', index) # Adjusts the spacing for row numbers
      colored_row = row.map do |cell|
        colored_cell = colorize_ship(cell)
        visible_length = colored_cell.gsub(/\e\[\d+(;\d+)*m/, '').length # Length without ANSI codes
        colored_cell.ljust(5 + colored_cell.length - visible_length) # Adjust for visible length
      end.join(' ')
      puts "#{formatted_row_number}    #{colored_row}"
    end
    nil
    # uncomment to be able to debug the algo better
    # sleep(0.3)
  end

  def colorize_ship(cell)
    # ANSI code for bold text is \e[1m
    bold_start = "\e[1m"
    bold_end = "\e[0m"

    case cell
    when 'I' # Irregular ship
      "#{bold_start}\e[31mI#{bold_end}" # Red
    when 'S' # Regular ship
      "#{bold_start}\e[38;5;220mS#{bold_end}" # Yellow
    when 'X' # Hit
      "#{bold_start}\e[38;5;33mX#{bold_end}" # Blue
    when '.' # Miss
      "#{bold_start}\e[31m.#{bold_end}" # Red
    else
      cell # No color for other cells
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

  def color_for_probability(prob, min_prob, max_prob)
    # Map negative probabilities to grayscale
    if prob < 0
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
end

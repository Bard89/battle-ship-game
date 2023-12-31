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
  #   # uncomment to be able to see step by step changes in the algo solving better
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
    # uncomment to be able to see step by step changes in the algo solving better
    # sleep(0.3)
  end

  def apply_formatting(text, apply_format, color_code)
    format_start = "\e[1m\e[38;5;#{color_code}m" # Start color and bold
    format_end = "\e[0m"
    apply_format ? "#{format_start}#{text}#{format_end}" : text
  end

  def formatted_header_or_label(text, is_target, spacing, color_code)
    formatted_text = text.to_s.center(spacing)
    apply_formatting(formatted_text, is_target, color_code)
  end

  # Main method to print the grid with the target row and column highlighted
  def print_target_grid(grid_string, target_row, target_column)
    purple_color_code = 198
    header_spacing = 5
    cell_spacing = 5

    column_headers = (0...Constants::GRID_SIZE).map do |col|
      formatted_header_or_label(col, col == target_column, header_spacing, purple_color_code)
    end.join(' ')
    puts (' ' * 9) + column_headers

    grid_string.chars.each_slice(Constants::GRID_SIZE).with_index do |row, index|
      formatted_row_number = formatted_header_or_label("Row #{index}", index == target_row, header_spacing + 1, purple_color_code)

      colored_row = row.map.with_index do |cell, col|
        colored_cell = colorize_ship(cell)
        colored_cell = apply_formatting(colored_cell, index == target_row || col == target_column, purple_color_code)
        adjust_cell_padding(colored_cell, cell_spacing)
      end.join(' ')

      puts "#{formatted_row_number}#{(' ' * 5)}#{colored_row}"
    end
    nil
    # sleep(0.3)
  end

  def adjust_cell_padding(colored_cell, cell_spacing)
    visible_length = colored_cell.gsub(/\e\[\d+(;\d+)*m/, '').length
    colored_cell.ljust(cell_spacing + colored_cell.length - visible_length)
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

  def print_target_and_probability_grid(regular, probability_grid, target_row, target_col, result)
    purple_bold_start = "\e[1m\e[38;5;198m"
    purple_bold_end = "\e[0m"

    puts "#{purple_bold_start}Targeted#{purple_bold_end}"
    print_target_grid(result['grid'], target_row, target_col)
    regular ? (puts "Regular ship probability grid:") : (puts "Irregular ship probability grid:")
    print_probability_grid(probability_grid)
  end
end

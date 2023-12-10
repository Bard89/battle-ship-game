require_relative 'constants.rb'

module Helpers
  def print_grid(grid_string)
    # Adding column headers (0 to 11) with spacing to match the grid
    column_headers = '        ' + (0...Constants::GRID_SIZE).map { |n| n.to_s.ljust(2) }.join(' ')
    puts column_headers

    # Printing each row with its row number
    grid_string.chars.each_slice(12).with_index do |row, index|
      formatted_row_number = format('Row %-3d', index) # Adjusts the spacing for row numbers
      puts "#{formatted_row_number} #{row.join('  ')}"
    end
  end

  # def print_probability_grid(probability_grid)
  #   # Adding column headers (0 to 11) with spacing to match the grid
  #   column_headers = '        ' + (0...Constants::GRID_SIZE).map { |n| n.to_s.ljust(4) }.join('  ')
  #   puts column_headers
  #
  #   # Printing each row with its row number
  #   probability_grid.each_with_index do |row, index|
  #     formatted_row_number = format('Row %-3d', index) # Adjusts the spacing for row numbers
  #     formatted_row = row.map { |prob| format_probability(prob) }.join('  ')
  #     puts "#{formatted_row_number} #{formatted_row}"
  #   end
  # end

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
    column_headers = '        ' + (0...Constants::GRID_SIZE).map { |n| n.to_s.ljust(4) }.join('  ')
    puts column_headers

    probability_grid.each_with_index do |row, index|
      formatted_row_number = format('Row %-3d', index) # Adjusts the spacing for row numbers
      formatted_row = row.map { |prob| "#{color_for_probability(prob, min_prob, max_prob)}#{'%.1f' % prob}\e[0m" }.join('  ')
      puts "#{formatted_row_number} #{formatted_row}"
    end
  end

  def valid_coordinates?(row, column)
    row.between?(0, Constants::GRID_SIZE - 1) && column.between?(0, Constants::GRID_SIZE - 1)
  end

  # def format_probability(probability)
  #   (probability * 100).round(2).to_s.ljust(4)
  # end
end

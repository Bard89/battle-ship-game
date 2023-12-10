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

  def print_probability_grid(probability_grid)
    # Adding column headers (0 to 11) with spacing to match the grid
    column_headers = '        ' + (0...Constants::GRID_SIZE).map { |n| n.to_s.ljust(4) }.join('  ')
    puts column_headers

    # Printing each row with its row number
    probability_grid.each_with_index do |row, index|
      formatted_row_number = format('Row %-3d', index) # Adjusts the spacing for row numbers
      formatted_row = row.map { |prob| format_probability(prob) }.join('  ')
      puts "#{formatted_row_number} #{formatted_row}"
    end
  end

  def valid_coordinates?(row, column)
    row.between?(0, Constants::GRID_SIZE - 1) && column.between?(0, Constants::GRID_SIZE - 1)
  end

  def format_probability(probability)
    (probability * 100).round(2).to_s.ljust(4)
  end
end

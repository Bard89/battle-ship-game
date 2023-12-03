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
end

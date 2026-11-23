module Edify
  # Formats rows as a plain-text table with a header row and columns padded to the widest value.
  module Table
    module_function

    # @param headers [Array<String>]
    # @param rows [Array<Array>]
    # @return [String]
    def render(headers, rows)
      cells = [headers, *rows].map { |row| row.map(&:to_s) }
      widths = headers.each_index.map { |column| cells.map { |row| row[column].length }.max }
      cells.map { |row| row.each_with_index.map { |cell, column| cell.ljust(widths[column]) }.join("  ").rstrip }
           .join("\n")
    end
  end
end

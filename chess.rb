require 'colorize'

class ChessError < StandardError
end

class Board
  def initialize
    @grid = Array.new(8) {Array.new(8)}
    populate_grid
  end

  def move(start, end_pos)
    raise ChessError.new "No piece" if board[start].nil?
    board[end_pos] = board[start]
    board[start] = nil
  end

  def [](pos)
    x, y = pos

    @grid[x][y]
  end

  def []=(pos, value)
    x, y = pos

    @grid[x][y] = value
  end

  def populate_grid
    start_rows = [0, 1, 6, 7]

    grid.each_index do |row|
      if start_rows.include?(row)
        row.each do |col|
          self[[row,col]] = Piece.new([row,col])
        end
      end
    end
  end
end

class Display
  KEYMAP = {
    " " => :space,
    "\e[A" => :up,
    "\e[B" => :down,
    "\e[C" => :right,
    "\e[D" => :left,
    "\177" => :backspace
  }

end

class Piece()
  attr_reader :pos
  def initialize(pos)
    @pos = pos
end

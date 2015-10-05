require 'colorize'
require "io/console"

class ChessError < StandardError

end


class Board
  attr_reader :grid
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

    @grid.each_index do |row|
      @grid[row].each_index do |col|
        if start_rows.include?(row)
          self[[row,col]] = Piece.new([row,col])
        else
          self[[row, col]] = "   "
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

  MOVES = {
    left:  [0, -1],
    right: [0, 1],
    up:    [-1, 0],
    down:  [1, 0]
  }

  def initialize(board)
    @board = board
    @cursor_pos = [0, 0]
  end

  def get_input
    key = KEYMAP[read_char]
    handle_key(key)
  end

  def read_char
    STDIN.echo = false
    STDIN.raw!

    input = STDIN.getc.chr
    if input == "\e" then
      input << STDIN.read_nonblock(3) rescue nil
      input << STDIN.read_nonblock(2) rescue nil
    end
  ensure
    STDIN.echo = true
    STDIN.cooked!

    return input
  end

  def handle_key(key)
    case key
    when :space
      nil
    when :backspace
      nil
      # deselect pos
    when :left, :right, :up, :down
      update_pos(MOVES[key])
    else
      puts key
    end
  end

  def update_pos(coords)
    @cursor_pos[0] += coords[0]
    @cursor_pos[1] += coords[1]
  end

  def colors_for(x, y)
    if [x, y] == @cursor_pos
      bg = :yellow
    elsif (x + y).odd?
      bg = :black
    else
      bg = :white
    end
    { background: bg }
  end

  def render
    system("clear")
    build_grid.each {|row| puts row.join}
  end

  def build_grid
    @board.grid.map.with_index do |row,i|
      build_row(row,i)
    end
  end

  def build_row (row,row_index)
    row.map.with_index do |col, col_index|
      color_options = colors_for(row_index, col_index)
      col.to_s.colorize(color_options)
    end
  end

end

class Piece
  attr_reader :pos

  def initialize(pos)
    @pos = pos
  end

  def to_s
    " P ".colorize(:red)
  end

end

board = Board.new
disp = Display.new(board)
3.times do
  disp.render
  disp.get_input
end
disp.render

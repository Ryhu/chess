require 'colorize'
require "io/console"

class ChessError < StandardError

end


class Board

  def self.in_bounds?(pos)
    pos.all? { |coord| coord.between?(0, 7) }
  end

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

  def is_empty?(pos)
    # Change if empty square representation changes
    board[pos] == " "
  end

  def populate_grid
    start_rows = [0, 1, 6, 7]

    @grid.each_index do |row|
      @grid[row].each_index do |col|
        if start_rows.include?(row)
          self[[row,col]] = Piece.new([row,col], :white, self)
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

    x = @cursor_pos[0] + coords[0]
    y = @cursor_pos[1] + coords[1]
    if Board.in_bounds?([x, y])
      @cursor_pos = [x, y]
    end
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

  attr_reader :pos, :color, :board
  def initialize(pos, color, board)
    @pos = pos
    @color = color
    @board = board
  end

  def to_s
    " P ".colorize(:red)
  end


end

class SlidingPiece < Piece

  def moves
    possible_moves = []

    move_dirs.each do |dir|

      valid_sq =  true
      start_pos = self.pos
      while valid_sq
        next_pos = [start_pos[0] + dir[0], start_pos[1] + dir[1]]
        if valid_pos?(next_pos)
          start_pos = next_pos
          possible_moves << next_pos
          valid_sq = false if board[next_pos].color != self.color
        else
          valid_sq = false
        end
      end
    possible_moves
  end

  def valid_pos(pos)
    return false if board[pos].color == self.color || Board.in_bounds?(pos)
    true
  end








  #   '''
  #   new_positions = move_dirs.map do |el|
  #     [el[0] + self.pos[0],el[1] + self.pos[1]]
  #   end
  #   new_positions.select! do |position|
  #     Board.in_bounds?(position) && board.empty?(pos)
  #   end
  #
  #   possible_moves += new_positions
  #   end
  #
  # end
  # '''
end

class Rook < SlidingPiece
  def move_dirs
    [[-1, 0], [1, 0], [0, -1], [0, 1]]
  end
end

class SteppingPiece < Piece

end

class King < SteppingPiece

end

class Pawn < Piece

end

board = Board.new
disp = Display.new(board)
3.times do
  disp.render
  disp.get_input
end
disp.render

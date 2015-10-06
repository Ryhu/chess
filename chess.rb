require 'colorize'
require "io/console"
require "byebug"

class ChessError < StandardError

end


class Board

  def self.in_bounds?(pos)
    pos.all? { |coord| coord.between?(0, 7) }
  end

  attr_reader :grid
  def initialize(populate = true)
    @grid = Array.new(8) { Array.new(8) }

    populate_grid if populate
  end

  def move(start, end_pos)
    raise ChessError.new "No piece" if board[start].nil?
    board[end_pos] = board[start]
    board[start] = nil
  end

  def dup
    dup_board = Board.new(false)
    8.times do |row_index|
      8.times do |col_index|

        current_pos = [row_index, col_index]
        if self[current_pos].is_a?(Piece)
          dup_board[current_pos] = self[current_pos].dup(dup_board)
        else
          dup_board[current_pos] = "   "
        end
      end
    end

    dup_board
  end

  def [](pos)
    x, y = pos

    @grid[x][y]
  end

  def []=(pos, value)
    x, y = pos

    @grid[x][y] = value
  end

  def king_pos(color)
    king = @grid.flatten.select do |piece|
      piece.is_a?(King) && piece.color == color
    end
    king[0].pos
  end

  def all_pieces(color)
    @grid.flatten.select {|piece| piece.is_a?(Piece) && (piece.color == color)}
  end

  def all_player_moves(color)
    all_player_moves = []
    all_pieces(color).each do |piece|
      all_player_moves += piece.moves
    end
  end

  def in_check?(color)
    king_pos = king_pos(color)
    other_color = (color == :black ? :white : :black)
    all_pieces(other_color).any? do |piece|
      piece.moves.include?(king_pos)
    end
  end

  def checkmate?(color)
    in_check?(color) &&
    all_player_moves(color).empty?

  end

  def is_empty?(pos)
    # Change if empty square representation changes
    board[pos] == "   "
  end

  def populate_grid
    start_rows = [0, 1, 6, 7]
    @grid.each_index do |row_index|
      if [0, 7].include?(row_index)
        @grid[row_index] = piece_row(row_index)
      elsif [1, 6].include?(row_index)
        @grid[row_index] = pawn_row(row_index)
      else
        @grid[row_index].each_index do |col_index|
          self[[row_index, col_index]] = "   "
        end
      end
    end
  end

  def piece_row(row_index)
    color = (row_index == 0 ? :black : :white)
    [ Rook.new([row_index,0], color, self),
      Knight.new([row_index,1], color, self),
      Bishop.new([row_index,2], color, self),
      Queen.new([row_index,3], color, self),
      King.new([row_index,4], color, self),
      Bishop.new([row_index,5], color, self),
      Knight.new([row_index,6], color, self),
      Rook.new([row_index,7], color, self),
    ]
  end

  def pawn_row(row_index)
    color = (row_index == 1 ? :black : :white)
    pawn_row = []
    8.times do |col_index|
      pawn_row << Pawn.new([row_index,col_index], color, self)
    end
    pawn_row
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
      bg = :green
    else
      bg = :light_red
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

  def valid_pos?(pos)
    return false unless Board.in_bounds?(pos)
    if board[pos].is_a?(Piece)
      return board[pos].color != self.color
    end
    true
  end

  def to_s
    " P ".colorize(:red)
  end

  def dup(duped_board)
    self.class.new(pos.dup, color, duped_board)
  end

  def move_into_check?(pos)
    dup_board = Board.new
    dup_board.grid =

    @grid.map
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
          valid_sq = false if board[next_pos].is_a?(Piece)
        else
          valid_sq = false
        end
      end
    end
    possible_moves
  end

end

class Rook < SlidingPiece
  def move_dirs
    [[-1, 0], [1, 0], [0, -1], [0, 1]]
  end

  def to_s
    " ♜ ".colorize(self.color)
  end
end

class Bishop < SlidingPiece
  def move_dirs
    [[-1, -1], [1, 1], [1, -1], [-1, 1]]
  end

  def to_s
    " ♝ ".colorize(self.color)
  end
end

class Queen < SlidingPiece
  def move_dirs
    [[-1, -1], [1, 1], [1, -1], [-1, 1], [-1, 0], [1, 0], [0, -1], [0, 1]]
  end

  def to_s
    " ♛ ".colorize(self.color)
  end
end

class SteppingPiece < Piece
  def moves
    next_moves = move_dirs.map { |dir| [dir[0] + pos[0], dir[1] + pos[1]]  }
    next_moves.select { |move| valid_pos?(move) }
  end
end

class King < SteppingPiece
  def move_dirs
    [[-1, -1], [1, 1], [1, -1], [-1, 1], [-1, 0], [1, 0], [0, -1], [0, 1]]
  end

  def to_s
    " ♚ ".colorize(self.color)
  end
end

class Knight < SteppingPiece
  def move_dirs
    [[-1,-2],[-1,2], [1,-2], [1,2], [-2,-1], [-2,1], [2,-1], [2,1]]
  end

  def to_s
    " ♞ ".colorize(self.color)
  end
end

class Pawn < Piece
  def move_dirs
    if color == :white
      move_dirs = {
        :diagonals => [[-1, 1], [-1, -1]],
        :forward => [-1,0],
        :forward2 => [-2,0]
      }
    else
      move_dirs = {
        :diagonals => [[1, -1], [1, 1]],
        :forward => [1,0],
        :forward2 => [2,0]
      }
    end
    move_dirs
  end




  def valid_forward?(pos)
    return false unless Board.in_bounds?(pos)
    !board[pos].is_a?(Piece)
  end

  def valid_diagonal?(pos)
    return false unless Board.in_bounds?(pos)
    if board[pos].is_a?(Piece)
      return board[pos].color != self.color
    end
    false
  end

  def moves
    moves = []
    move_dirs[:diagonals].each do |diagonal|
      move = get_move_pos(diagonal)
      moves << move if valid_diagonal?(move)
    end
    one_forward = get_move_pos(move_dirs[:forward])
    two_forward = get_move_pos(move_dirs[:forward2])
    if valid_forward?(one_forward)
      moves << one_forward
      if valid_forward?(two_forward)
        moves << two_forward
      end
    end
    moves
  end

  def get_move_pos(direction)
    [pos[0] + direction[0], pos[1] + direction[1]]
  end

  def to_s
    " ♟ ".colorize(self.color)
  end
end

board = Board.new

# board[[2,3]] = Knight.new([2,3], :white, board)
p board.in_check?(:black)

# board[[3,3]] = Bishop.new([3,3], :black, board)
# p board[[3,3]].moves


#
# disp = Display.new(board)
#
# 3.times do
#   disp.render
#   disp.get_input
# end
# disp.render

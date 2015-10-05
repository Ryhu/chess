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

  MOVES = {
    left:  [0, -1],
    right: [0, 1],
    up:    [1, 0],
    down:  [-1, 0]
  }

  def initialize(board)
    @board = board
    @cursor_pos = [0, 0]
  end

  def get_input
    key = KEYMAP[read_char]
    handle_key(key)
  end

  def handle_key(key)
    case key
    when :space
      # select pos
    when :backspace
      # deselect pos
    when :left, :right, :up, :down
      update_pos(MOVES[key])
    else
      puts key
    end
  end

  def update_pos(coords)
    @cursor_pos[0] += coords[0]
    @cursos_pos[1] += coords[1]
  end

  def colors_for(x,y)
    if [x, y] = @cursor_pos
      bg = :yellow
    elsif (x + y) = odd
      bg = :black
    else
      bg = :white
    end
    { background: bg }
  end


end

class Piece()
  attr_reader :pos
  def initialize(pos)
    @pos = pos
end

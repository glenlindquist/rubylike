require 'gosu'
require_relative 'coordinates'
require_relative 'player'
require_relative 'tile'
require_relative 'map'

class MainWindow < Gosu::Window
  WIDTH = 640
  HEIGHT = 480
  FONT = "Courier"
  FONT_SIZE = TILE_SIZE = 16
  X_WIDTH = WIDTH / FONT_SIZE
  Y_WIDTH = HEIGHT / FONT_SIZE
  INPUT_DELAY = 150 #milliseconds

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Rubylike"
    @main_font = Gosu::Font.new(FONT_SIZE, name: FONT)
    @sprites = Gosu::Image.load_tiles('assets/sprites/main.png', 16, 16)
    @screen = {}
    @gui = {}
    @player = Player.new
    @last_input_at = -1 - INPUT_DELAY
    @last_update_at = 0
    @player_sprite = @sprites[1]
    @map = Map.new
    @camera = Camera.new
    init_screen(@sprites[250])
    
  end

  def update
    @last_update_at = Gosu.milliseconds
    if @last_update_at - @last_input_at > INPUT_DELAY
      handle_input
    end
    update_screen
  end

  def draw
    Gosu.draw_rect(0,0, WIDTH, HEIGHT, 0xff_00aa00)
    draw_screen
  end

  def init_screen(sprite = @sprites[250])
    (0...Y_WIDTH).each do |y|
      (0...X_WIDTH).each do |x|
        @screen[Coordinates.new(x,y)] = sprite
      end
    end
    create_border(@sprites[3])
    @screen[@player.coordinates] = @player_sprite
  end

  def update_camera
    if @player.position.x - @camera.position.x <= @camera.buffer_x
      @camera.position.x -= 1
    end
    if @player.position.y - @camera.position.y <= @camera.buffer_y
      @camera.position.y -= 1
    end
    if @player.position.x + @camera.position.x <= @camera.buffer_x
      @camera.position.x += 1
    end
    if @player.position.y + @camera.position.y <= @camera.buffer_y
      @camera.position.y += 1
    end
  end

  def update_screen
    @screen.each do |coordinates, sprite|
      if @map.tiles[(coordinates + @player.coordinates)]
        @screen[coordinates] = @sprites[
          @map.tiles[(coordinates + @player.coordinates)].type
        ]
      else
        @screen[coordinates] = @sprites[0] #off the edge of map
      end
    end
    @screen[@player.coordinates - @camera.coordinates] = @player_sprite
  end

  def handle_input
    if Gosu.button_down? Gosu::KB_LEFT
      @player.coordinates.x -= 1
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_RIGHT
      @player.coordinates.x += 1
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_UP
      @player.coordinates.y -=1
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_DOWN
      @player.coordinates.y +=1
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_Q
      pp "Dtime: #{@d_time}
      G.mill: #{Gosu.milliseconds}"
      @last_input_at = Gosu.milliseconds
    end
  end


  def button_down(id)

    case id
    # when Gosu::KB_LEFT
    #   @player.coordinates.x -= 1
    # when Gosu::KB_RIGHT
    #   @player.coordinates.x += 1
    # when Gosu::KB_UP
    #   @player.coordinates.y -= 1
    # when Gosu::KB_DOWN
    #   @player.coordinates.y += 1
    when Gosu::KB_ESCAPE
      close
    # when Gosu::KB_Q
    #   pp "Debug"
    else
      super
    end
  end

  def draw_screen
    @screen.each do |coordinates, sprite|
      if coordinates == Coordinates.new(5,5)
        sprite.draw(coordinates.x * TILE_SIZE, coordinates.y * TILE_SIZE, 1, 1, 1, 0xff_ffffff)
      else
        sprite.draw(coordinates.x * TILE_SIZE, coordinates.y * TILE_SIZE, 1, 1, 1, 0xff_006622)
      end
    end
  end

  def create_border(border_sprite)
    @screen.each do |coordinates, sprite|
      if  coordinates.x == 0 || 
          coordinates.y == 0 || 
          coordinates.x == X_WIDTH - 1 || 
          coordinates.y == Y_WIDTH - 1
        @screen[coordinates] = border_sprite
      end
    end
  end

end

class Camera
  attr_accessor :coordinates, :buffer_x, :buffer_y
  def initialize(buffer_x = 10, buffer_y = 10)
    @coordinates = Coordinates.new(0,0)
    @buffer_x = 10
    @buffer_y = 10
  end

end

MainWindow.new.show
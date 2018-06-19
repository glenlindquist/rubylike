require 'gosu'
require 'RMagick'
require_relative 'coordinates'
require_relative 'player'
require_relative 'tile'
require_relative 'map'
require_relative 'feature'
require_relative 'sprite_text'

class MainWindow < Gosu::Window
  attr_reader :main_font, :sprites, :screen, :gui, :player, :map, :camera
  WIDTH = 960
  HEIGHT = 720
  GAME_WIDTH = 640
  GAME_HEIGHT = 480
  FONT = "Courier"
  FONT_SIZE = TILE_SIZE = 16
  X_WIDTH = GAME_WIDTH / TILE_SIZE
  Y_WIDTH = GAME_HEIGHT / TILE_SIZE
  INPUT_DELAY = 150 #milliseconds

  def initialize
    $window = self
    super WIDTH, HEIGHT
    self.caption = "Rubylike"
    @main_font = Gosu::Font.new(FONT_SIZE, name: FONT)
    @sprites = Gosu::Image.load_tiles('assets/sprites/main.png', 16, 16)
    @screen = {}
    @gui = {}
    @player = Player.new
    # @player.window = self
    @last_input_at = -1 - INPUT_DELAY
    @last_update_at = 0
    @player_sprite = @sprites[1]
    @map = Map.new
    @camera = Camera.new(10,5)
    init_screen(@sprites[250])
    @test_text = SpriteText.new("99Gorillas")
  end

  # --- Main loops --- #
  def update
    @last_update_at = Gosu.milliseconds
    if @last_update_at - @last_input_at > INPUT_DELAY
      handle_input
    end
    update_camera
    update_screen
  end

  def draw
    draw_screen
    draw_gui
    @test_text.draw(640,0,0)
  end
  # ------------------ #

  def init_screen(sprite = @sprites[250])
    (0...Y_WIDTH).each do |y|
      (0...X_WIDTH).each do |x|
        @screen[Coordinates.new(x,y)] = sprite
      end
    end
  end

  def update_screen
    @screen.each do |coordinates, sprite|
      if @map.tiles[(coordinates + @camera.coordinates)]
        @screen[coordinates] = @sprites[
          @map.tiles[(coordinates + @camera.coordinates)].sprite_index
        ]
      else
        @screen[coordinates] = @sprites[0] #off the edge of map
      end
    end
  end

  def draw_screen
    @screen.each do |coordinates, sprite|
      tile = tile_at_screen_coordinates(coordinates)
      # Background color for tile
      Gosu.draw_rect(
        coordinates.x * TILE_SIZE,
        coordinates.y * TILE_SIZE,
        TILE_SIZE,
        TILE_SIZE,
        tile.bg_color
      )
      # Foreground
      sprite.draw(
        coordinates.x * TILE_SIZE,
        coordinates.y * TILE_SIZE,
        1,
        1,
        1,
        tile.fg_color
      )
      # Draw features
      if @map.features.include?(screen_coordinates_to_map_coordinates(coordinates))
        feature = @map.features[screen_coordinates_to_map_coordinates(coordinates)]
        @sprites[feature.sprite_index].draw(
          coordinates.x * TILE_SIZE,
          coordinates.y * TILE_SIZE,
          1,
          1,
          1,
          feature.fg_color
        )
      end

      # Draw player
      if coordinates = @player.screen_coordinates
        @player_sprite.draw(
          coordinates.x * TILE_SIZE,
          coordinates.y * TILE_SIZE,
          1,
          1,
          1,
          0xff_FDB959
        )
      end
    end
  end

  def draw_gui
    # pending
  end

  def update_camera
    if @player.coordinates.x - @camera.coordinates.x <= @camera.buffer_x
      @camera.coordinates.x -= 1
    end
    if @player.coordinates.y - @camera.coordinates.y <= @camera.buffer_y
      @camera.coordinates.y -= 1
    end
    if X_WIDTH - @player.coordinates.x + @camera.coordinates.x <= @camera.buffer_x
      @camera.coordinates.x += 1
    end
    if Y_WIDTH - @player.coordinates.y + @camera.coordinates.y <= @camera.buffer_y
      @camera.coordinates.y += 1
    end
  end

  def handle_input
    if Gosu.button_down? Gosu::KB_LEFT
      @player.coordinates.x -= 1 if @map.tile_at(Coordinates.new(@player.coordinates.x - 1, @player.coordinates.y)).navigable?
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_RIGHT
      @player.coordinates.x += 1 if @map.tile_at(Coordinates.new(@player.coordinates.x + 1, @player.coordinates.y)).navigable?
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_UP
      @player.coordinates.y -=1 if @map.tile_at(Coordinates.new(@player.coordinates.x, @player.coordinates.y - 1)).navigable?
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_DOWN
      @player.coordinates.y +=1 if @map.tile_at(Coordinates.new(@player.coordinates.x, @player.coordinates.y + 1)).navigable?
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_Y
      @player.coordinates += Coordinates.new(-1,-1) if @map.tile_at(@player.coordinates + Coordinates.new(-1,-1)).navigable?
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_U
      @player.coordinates += Coordinates.new(1,-1) if @map.tile_at(@player.coordinates + Coordinates.new(1,-1)).navigable?
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_B
      @player.coordinates += Coordinates.new(-1,1) if @map.tile_at(@player.coordinates + Coordinates.new(-1,1)).navigable?
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_N
      @player.coordinates += Coordinates.new(1,1) if @map.tile_at(@player.coordinates + Coordinates.new(1,1)).navigable?
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_Q
      pp "camera: #{@camera.coordinates.x} #{@camera.coordinates.y}"
      pp "player: #{@player.coordinates.x} #{@player.coordinates.y}"
      pp "player -camera: #{(@player.coordinates - @camera.coordinates).x}"
      pp "FPS: #{Gosu.fps}"
      @player.find_nearest_feature("tree").fg_color = 0xff_ff0000
      @last_input_at = Gosu.milliseconds
    end
  end

  def button_down(id)
    case id
    when Gosu::KB_ESCAPE
      close
    else
      super
    end
  end

  def screen_coordinates_to_map_coordinates(coordinates)
    coordinates + @camera.coordinates
  end

  def tile_at_screen_coordinates(coordinates)
    @map.tile_at(screen_coordinates_to_map_coordinates(coordinates))
  end

end

class Camera
  attr_accessor :coordinates, :buffer_x, :buffer_y
  def initialize(buffer_x = 10, buffer_y = 10)
    @coordinates = Coordinates.new(0,0)
    @buffer_x = buffer_x
    @buffer_y = buffer_y
  end
end

MainWindow.new.show
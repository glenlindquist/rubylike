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

  FONT = "Courier"
  FONT_SIZE = TILE_SIZE = 16
  INPUT_DELAY = 150 #milliseconds

  # Full window
  WIDTH = 960
  HEIGHT = 720

  # Game window
  GAME_WIDTH = 640
  GAME_HEIGHT = 480
  TILES_WIDE = GAME_WIDTH / TILE_SIZE
  TILES_HIGH = GAME_HEIGHT / TILE_SIZE

  # Sidebar
  SIDEBAR_X_START = GAME_WIDTH
  SIDEBAR_WIDTH = WIDTH - GAME_WIDTH
  SIDEBAR_HEIGHT = HEIGHT

  # Toolbar
  TOOLBAR_Y_START = GAME_HEIGHT
  TOOLBAR_WIDTH = GAME_WIDTH
  TOOLBAR_HEIGHT = HEIGHT - GAME_HEIGHT

  def initialize
    $window = self
    super WIDTH, HEIGHT
    self.caption = "Rubylike"
    @main_font = Gosu::Font.new(FONT_SIZE, name: FONT)
    @sprites = Gosu::Image.load_tiles('assets/sprites/main.png', 16, 16)
    @screen = {}
    @gui = {}
    @last_input_at = -1 - INPUT_DELAY
    @last_update_at = 0
    @player_sprite = @sprites[1]
    @map = Map.new
    @player = Player.new(@map.find_solid_ground(Coordinates.new(0,0)))
    #@player = Player.new(Coordinates.new(0,0))
    @camera = Camera.new(10,5)
    init_screen(@sprites[250])
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
    #draw_overlay
    draw_gui
  end
  # ------------------ #

  def init_screen(sprite = @sprites[250])
    (0...TILES_HIGH).each do |y|
      (0...TILES_WIDE).each do |x|
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
      tile ||= Tile.new(coordinates, "water")
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

  def draw_overlay 
    @screen.each do |coordinates, sprite|
      player_distance = Coordinates.distance(coordinates, @player.screen_coordinates)
      #player_distance = 11
      case
      # when features[screen_coordinates_to_map_coordinates(coordinates)]
      when player_distance <= 10
        Gosu.draw_rect(
          coordinates.x * TILE_SIZE,
          coordinates.y * TILE_SIZE,
          TILE_SIZE,
          TILE_SIZE,
          Gosu::Color.new(player_distance * (255 / 10),0,0,25),
          999
        )
      else
        Gosu.draw_rect(
          coordinates.x * TILE_SIZE,
          coordinates.y * TILE_SIZE,
          TILE_SIZE,
          TILE_SIZE,
          Gosu::Color.new(255,0,0,25),
          999
        )
      end
    end
  end

  # -- GUI -- #
  def draw_gui
    #SpriteText.new("99Gorillas").draw(640,0,0)

    # Sidebar frame
    draw_frame(SIDEBAR_X_START, 0, SIDEBAR_WIDTH / TILE_SIZE, SIDEBAR_HEIGHT / TILE_SIZE, 0)

    # Minimap
    minimap_x_start = SIDEBAR_X_START + TILE_SIZE
    minimap_y_start = TILE_SIZE
    @map.minimap.each do |coordinates, tile|
      @sprites[tile.sprite_index].draw(
        minimap_x_start + coordinates.x * TILE_SIZE,
        minimap_y_start + coordinates.y * TILE_SIZE,
        0,
        1,
        1,
        tile.fg_color
      )
    end
    player_minimap_coords = @map.world_coordinates_to_minimap_coordinates(@player.coordinates)

    @player_sprite.draw(
      minimap_x_start + player_minimap_coords.x * TILE_SIZE,
      minimap_y_start + player_minimap_coords.y * TILE_SIZE,
      1,
      1,
      1,
      0xff_FDB959
    )
    
    # Day / night
    (SIDEBAR_X_START / TILE_SIZE + 1..WIDTH / TILE_SIZE - 2).each do |x|
      case x
      when SIDEBAR_X_START / TILE_SIZE + 1
        #begin
        sprite_index = 195
      when WIDTH / TILE_SIZE - 2
        #end
        sprite_index = 180
      when SIDEBAR_X_START / TILE_SIZE + 2
        #sun
        sprite_index = 42
      else
        #middle
        sprite_index = 196
      end
      @sprites[sprite_index].draw(
        x * TILE_SIZE,
        20 * TILE_SIZE,
        1,
        1,
        1,
        sprite_index == 42 ? 0xff_ffff00 : 0xff_ffffff
      )
    end

    # Toolbar frame
    draw_frame(0, TOOLBAR_Y_START, (TOOLBAR_WIDTH / TILE_SIZE), TOOLBAR_HEIGHT / TILE_SIZE, 0)
  end

  def draw_frame(x, y, tiles_wide, tiles_high, sprite_index)
    (0...tiles_high).each do |tile_y|
      (0...tiles_wide).each do |tile_x|
        case
        when tile_y == 0 && tile_x == 0
          #upper left
          @sprites[201].draw(x + tile_x * TILE_SIZE, y + tile_y * TILE_SIZE, 0)
        when tile_y == 0 && tile_x == tiles_wide - 1
          #upper right
          @sprites[187].draw(x + tile_x * TILE_SIZE, y + tile_y * TILE_SIZE, 0)
        when tile_y == tiles_high - 1 && tile_x == 0
          #lower left
          @sprites[200].draw(x + tile_x * TILE_SIZE, y + tile_y * TILE_SIZE, 0)
        when tile_y == tiles_high - 1 && tile_x == tiles_wide -1
          #lower right
          @sprites[188].draw(x + tile_x * TILE_SIZE, y + tile_y * TILE_SIZE, 0)
        when tile_y == 0
          #upper
          @sprites[205].draw(x + tile_x * TILE_SIZE, y + tile_y * TILE_SIZE, 0)
        when tile_y == tiles_high - 1
          #lower
          @sprites[205].draw(x + tile_x * TILE_SIZE, y + tile_y * TILE_SIZE, 0)
        when tile_x == 0
          #left
          @sprites[186].draw(x + tile_x * TILE_SIZE, y + tile_y * TILE_SIZE, 0)
        when tile_x == tiles_wide - 1
          #right
          @sprites[186].draw(x + tile_x * TILE_SIZE, y + tile_y * TILE_SIZE, 0)
        end
      end
    end
  end

  def update_camera
    if @player.coordinates.x - @camera.coordinates.x <= @camera.buffer_x
      @camera.coordinates.x -= 1
    end
    if @player.coordinates.y - @camera.coordinates.y <= @camera.buffer_y
      @camera.coordinates.y -= 1
    end
    if TILES_WIDE - @player.coordinates.x + @camera.coordinates.x <= @camera.buffer_x
      @camera.coordinates.x += 1
    end
    if TILES_HIGH - @player.coordinates.y + @camera.coordinates.y <= @camera.buffer_y
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
    @coordinates = $window.player.coordinates - Coordinates.new(MainWindow::TILES_WIDE / 2, MainWindow::TILES_HIGH / 2)
    @buffer_x = buffer_x
    @buffer_y = buffer_y
  end
end

MainWindow.new.show
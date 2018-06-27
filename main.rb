require 'gosu'
require 'RMagick'
require_relative 'coordinates'
require_relative 'player'
require_relative 'tile'
require_relative 'map'
require_relative 'feature'
require_relative 'sprite_text'

class Integer
  def tiles
    self * MainWindow::TILE_SIZE
  end
  alias :tile :tiles
end

# class Hash
#   def include_coordinates?(coordinates)
#     self.include?(coordinates.dup)
#   end
# end

class MainWindow < Gosu::Window
  attr_reader :main_font, :sprites, :screen, :gui, :player, :map, :camera, :meters, :player_sprite, :player_avatar_sprite, :avatar, :avatar_beard, :timer

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

  # Gameplay
  DAY_LENGTH = 1000.0

  def initialize
    $window = self
    super WIDTH, HEIGHT
    self.caption = "Rubylike"
    @main_font = Gosu::Font.new(FONT_SIZE, name: FONT)
    @sprites = Gosu::Image.load_tiles('assets/sprites/main.png', 16, 16)
    @health_sprites = Gosu::Image.load_tiles('assets/sprites/health.png', 16, 16)
    @solid_tile_sprite = Gosu::Image.new('assets/sprites/tile.png')
    @selector = Gosu::Image.new('assets/sprites/selector_a.png')
    @cursor = Gosu::Image.new('assets/sprites/cursor.png')
    @screen = {}
    @meters = {}
    @last_input_at = -1 - INPUT_DELAY
    @last_update_at = 0
    @player_sprite = Gosu::Image.new('assets/sprites/player_simple.png')
    @player_avatar_sprite = Gosu::Image.new('assets/sprites/player_avatar.png')
    @avatar = {}
    @avatar_beard = {}
    @tile_line = []
    @map = Map.new
    @player = Player.new(@map.find_solid_ground(Coordinates.new(0,0)))
    @camera = Camera.new(15,15)
    @timer = 0.0
    init_screen(@sprites[250])
    init_avatar
  end

  def needs_cursor?
    false
  end

  # --- Main loops --- #
  def update
    @last_update_at = Gosu.milliseconds
    if @last_update_at - @last_input_at > INPUT_DELAY
      handle_input
    end
    @player.update
    update_camera
    update_screen
  end

  def draw
    @cursor.draw(self.mouse_x, self.mouse_y, 9999)
    draw_screen
    draw_overlay
    draw_gui
    draw_debug

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
        @map.tiles[coordinates + @camera.coordinates] = Tile.new(coordinates + @camera.coordinates, "water")
      end
    end
  end

  def draw_screen
    @screen.each do |coordinates, sprite|
      tile = tile_at_screen_coordinates(coordinates)
      tile ||= Tile.new(screen_coordinates_to_map_coordinates(coordinates), "water")

      # Background
      @solid_tile_sprite.draw(
        coordinates.x * TILE_SIZE,
          coordinates.y * TILE_SIZE,
          0,
          1,
          1,
          tile.bg_color
        )
    

      # Foreground
      @sprites[tile.sprite_index].draw(
        coordinates.x * TILE_SIZE,
        coordinates.y * TILE_SIZE,
        0,
        1,
        1,
        tile.fg_color
      )
      # Draw features
      # if @map.features.include?(screen_coordinates_to_map_coordinates(coordinates))
      #   feature = @map.features[screen_coordinates_to_map_coordinates(coordinates)]
      #   @sprites[feature.sprite_index].draw(
      #     coordinates.x * TILE_SIZE,
      #     coordinates.y * TILE_SIZE,
      #     1,
      #     1,
      #     1,
      #     feature.fg_color
      #   )
      # end

      # Draw player
      if coordinates = @player.screen_coordinates
        @player_sprite.draw(
          coordinates.x * TILE_SIZE,
          coordinates.y * TILE_SIZE,
          2,
          1,
          1,
          0xff_FDB959
        )
      end
    end
  end

  def draw_overlay 
    @screen.each do |coordinates, sprite|
      player_distance = Coordinates.tile_distance(coordinates, @player.screen_coordinates)
      if player_distance <= @player.vision_radius
        feature = @map.features[screen_coordinates_to_map_coordinates(coordinates)]
        @sprites[feature.sprite_index].draw(
          coordinates.x * 1.tile,
          coordinates.y * 1.tile,
          1,
          1,
          1,
          feature.fg_color
        ) if feature
        elsif @map.tile_at(screen_coordinates_to_map_coordinates(coordinates)) && @map.tile_at(screen_coordinates_to_map_coordinates(coordinates)).known
          @solid_tile_sprite.draw(
            coordinates.x * 1.tile,
            coordinates.y * 1.tile,
            10,
            1,
            1,
            Gosu::Color.new(180,0,0,25)
          )
        else
          @solid_tile_sprite.draw(
            coordinates.x * 1.tile,
            coordinates.y * 1.tile,
            10,
            1,
            1,
            Gosu::Color.new(255,0,0,25)
          )
      end
    end
  end

  # ------ GUI ------ #
  # ----------------- #

  def init_avatar
    avatar = Magick::Image.from_blob(@player_avatar_sprite.to_blob){
      self.format = "RGBA"
      self.size = "#{$window.player_avatar_sprite.width}x#{$window.player_avatar_sprite.height}"
      self.depth = 8
    }.first
    pixel_array = avatar.get_pixels(0, 0 , $window.player_avatar_sprite.width, $window.player_avatar_sprite.height)
    pp pixel_array[18].to_color
    pixel_array.each_with_index do |pixel, index|
      x = index % $window.player_avatar_sprite.width
      y = (index / $window.player_avatar_sprite.height)
      key = nil
      case pixel.to_color
      when "black"
        key = "black"
      when "white"
        key = "white"
      when "#BBBBBBBBBBBB"
        key = "beard"
        @avatar_beard[Coordinates.new(x,y)] = 0
      when "red"
        key = "empty"
      else
        key = "beard"
      end
      @avatar[Coordinates.new(x,y)] = key
    end
  end

  def draw_gui
    # Target
    if @player.target
      target_on_screen = map_coordinates_to_screen_coordinates(@player.target)
      @selector.draw(target_on_screen.x * 1.tile, target_on_screen.y * 1.tile, 99, 1, 1, 0xff_ff0000)
    end

    #On-screen condition/health meters
    @meters.each do |coordinates, condition|
      screen_coordinates = map_coordinates_to_screen_coordinates(coordinates)
      #14 sprites in health meter
      health_index = 13 - (condition * 14.0).floor
      @health_sprites[health_index].draw(
        screen_coordinates.x * 1.tile,
        screen_coordinates.y * 1.tile + 1.tile/4,
        99
      )
    end

    # Sidebar
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
    
    # Clock / Timer
    timer_width = SIDEBAR_WIDTH / TILE_SIZE - 4
    clock_position = ((@timer % DAY_LENGTH) / DAY_LENGTH * timer_width).floor
    (SIDEBAR_X_START / TILE_SIZE + 1..WIDTH / TILE_SIZE - 2).each do |x|
      case x
      when SIDEBAR_X_START / TILE_SIZE + 1
        #begin
        sprite_index = 195
      when WIDTH / TILE_SIZE - 2
        #end
        sprite_index = 180
      when SIDEBAR_X_START / TILE_SIZE + 2 + clock_position
        #sun
        sprite_index = 42
      else
        #middle
        sprite_index = 196
      end
      @sprites[sprite_index].draw(
        x * TILE_SIZE,
        (Map::MINIMAP_DESIRED_WIDTH + 2) * TILE_SIZE,
        1,
        1,
        1,
        sprite_index == 42 ? 0xff_ffff00 : 0xff_ffffff
      )
    end
    SpriteText.new("Time: #{@timer.to_s}").draw(SIDEBAR_X_START + TILE_SIZE, (Map::MINIMAP_DESIRED_WIDTH + 3) * TILE_SIZE, 0)
    
    # Inventory
    inventory_y_start = Map::MINIMAP_DESIRED_WIDTH * 1.tile + 5.tiles
    # SpriteText.new("Inventory:").draw(
    #   SIDEBAR_X_START + 1.tiles,
    #   inventory_y_start - 1,
    #   0
    # )
    @player.inventory.each do |slot, item|
      slot_math = slot == 0 ? 10 : slot
      if slot == @player.selected_inventory_slot
        Gosu.draw_rect(
          SIDEBAR_X_START + 1.tile,
          inventory_y_start + slot_math * 2.tiles,
          8.tiles,
          1.tile,
          0xff_222222
          )
      end
      SpriteText.new("#{slot.to_s}: ").draw(
        SIDEBAR_X_START + 1.tiles, 
        inventory_y_start + slot_math * 2.tiles, 
        0
      )
      if !item.empty?
        sprite_index = Feature.get_sprite(item[0])
        color = Feature.get_fg_color(item[0])
        @sprites[sprite_index].draw(
          SIDEBAR_X_START + 4.tiles,
          inventory_y_start + slot_math * 2.tiles,
          0,
          1,
          1,
          color
        )
        SpriteText.new("x#{item[1].to_s}").draw(
          SIDEBAR_X_START + 6.tiles, 
          inventory_y_start + slot_math * 2.tiles,
          0
        )
      end
    end

    # Beard indicator
    SpriteText.new("Beard:").draw(
      (SIDEBAR_X_START + 11.tiles),
      inventory_y_start,
      99
    )
    @avatar.each do |coordinates, type|
      case type
      when "black"
        sprite_index = 32
        sprite_color = 0xff_000000
        bg_color = 0xff_000000
      when "white"
        sprite_index = 32
        sprite_color = 0xff_e2a146
        bg_color = 0xff_FDB959
      when "empty"
        sprite_index = 32
        sprite_color = 0xff_000000
        bg_color = 0xff_000000
      when "beard"
        sprite_color = 0xff_634A1B
        bg_color = 0xff_FDB959
        sprite_index = 32 
      else
      end
      #background
      @solid_tile_sprite.draw(
        (SIDEBAR_X_START + 10.tiles) + coordinates.x * 1.tile,
        inventory_y_start + 2.tiles + coordinates.y * 1.tile,
        99,
        1,
        1,
        bg_color
      )

    end

    @avatar_beard.each do |coordinates, beard_growth|
      sprite_index = 32
      sprite_index = 176 if beard_growth == 1
      sprite_index = 177 if beard_growth == 2
      sprite_index = 178 if beard_growth == 3
      #bg_color = 0xff_634A1B if @player.beard_level > 75
      sprite_color = 0xff_634A1B

      #sprite
      @sprites[sprite_index].draw(
        (SIDEBAR_X_START + 10.tiles) + coordinates.x * 1.tile,
        inventory_y_start + 2.tiles + coordinates.y * 1.tile,
        99,
        1,
        1,
        sprite_color
      )
    end


    # Toolbar
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

  def draw_debug
    @tile_line.each do |coordinates|
      screen_coordinates = map_coordinates_to_screen_coordinates(coordinates)
      @sprites[0].draw(
        screen_coordinates.x * 1.tile,
        screen_coordinates.y * 1.tile,
        9999,
        1,
        1,
        0x99_ff0000
      )
    end
    coordinates = map_coordinates_to_screen_coordinates(@player.find_nearest_feature("tree").coordinates)
    player_screen = map_coordinates_to_screen_coordinates(
      @player.coordinates
    )
    Gosu::draw_line(
      player_screen.x * 1.tile,
      player_screen.y * 1.tile,
      0x99_ff0000,
      (coordinates.x * 1.tile) - (0.5 * TILE_SIZE),
      (coordinates.y * 1.tile) - (0.5 * TILE_SIZE),
      0x99_ff0000,
      9999
    )
    Gosu::draw_line(
      player_screen.x * 1.tile,
      player_screen.y * 1.tile,
      0x99_ff0000,
      (coordinates.x * 1.tile) + (0.5 * TILE_SIZE),
      (coordinates.y * 1.tile) + (0.5 * TILE_SIZE),
      0x99_ff0000,
      9999
    )
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
      @player.move("west")
      @last_input_at = Gosu.milliseconds
      @timer += @player.movement_cost
    end
    if Gosu.button_down? Gosu::KB_RIGHT
      @player.move("east")
      @last_input_at = Gosu.milliseconds
      @timer += @player.movement_cost
    end
    if Gosu.button_down? Gosu::KB_UP
      @player.move("north")
      @last_input_at = Gosu.milliseconds
      @timer += @player.movement_cost
    end
    if Gosu.button_down? Gosu::KB_DOWN
      @player.move("south")
      @last_input_at = Gosu.milliseconds
      @timer += @player.movement_cost
    end
    if Gosu.button_down? Gosu::KB_Y
      @player.move("northwest")
      @last_input_at = Gosu.milliseconds
      @timer += @player.movement_cost
    end 
    if Gosu.button_down? Gosu::KB_U
      @player.move("northeast")
      @last_input_at = Gosu.milliseconds
      @timer += @player.movement_cost
    end
    if Gosu.button_down? Gosu::KB_B
      @player.move("southwest")
      @last_input_at = Gosu.milliseconds
      @timer += @player.movement_cost
    end
    if Gosu.button_down? Gosu::KB_N
      @player.move("southeast")
      @last_input_at = Gosu.milliseconds
      @timer += @player.movement_cost
    end
    if Gosu.button_down? Gosu::KB_Q
      #Debug stuff
      pp "FPS: #{Gosu.fps}"
      feature_coords = @player.find_nearest_feature("tree").coordinates
      @tile_line = Coordinates.bresenhams_line(@player.coordinates, feature_coords)

      #Harvest tree
      @player.harvest("tree")
      @last_input_at = Gosu.milliseconds
      @timer += @player.movement_cost
    end
    if Gosu.button_down? Gosu::KB_S
      # @player.shave
      @avatar = {}
      @avatar_beard = {}
      @player.last_shaved_at = @timer
      @player.beard_level = 0
      @player.beard_threshold = 10
      init_avatar
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_G
      if @map.features[@player.coordinates]
        if @player.add_to_inventory(@map.features[@player.coordinates].type)
          @map.features.delete(@player.coordinates)
        else
          # couldn't pick up
        end
      end
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_D
      item = @player.inventory[@player.selected_inventory_slot][0]
      if @player.remove_from_inventory(@player.selected_inventory_slot)
        new_coords = @player.coordinates.dup
        @map.features[new_coords] = Feature.new(new_coords, item)
      else
        # couldn't drop
      end
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_1
      @player.selected_inventory_slot = 1
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_2
      @player.selected_inventory_slot = 2
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_3
      @player.selected_inventory_slot = 3
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_4
      @player.selected_inventory_slot = 4
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_5
      @player.selected_inventory_slot = 5
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_6
      @player.selected_inventory_slot = 6
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_7
      @player.selected_inventory_slot = 7
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_8
      @player.selected_inventory_slot = 8
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_9
      @player.selected_inventory_slot = 9
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_0
      @player.selected_inventory_slot = 0
      @last_input_at = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::MS_LEFT
      x = ($window.mouse_x / 1.tile).floor
      y = ($window.mouse_y / 1.tile).floor
      pp "screen: #{x}, #{y}"
      mouse_on_map = screen_coordinates_to_map_coordinates(Coordinates.new(x,y))
      if @map.features.include?(mouse_on_map)
        @player.target = mouse_on_map.dup
      end
      pp "map: #{mouse_on_map.x}, #{mouse_on_map.y}"
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

  def map_coordinates_to_screen_coordinates(coordinates)
    coordinates - @camera.coordinates
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

Gosu::enable_undocumented_retrofication
MainWindow.new.show
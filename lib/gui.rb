module GUI
  class Window
    attr_reader :width, :height, :border, :background, :color, :title
    def initialize(width, height, z = 99, title = nil, border = true, background = true, color = 0xff_000000)
      @width = width
      @height = height
      @border = border
      @background = background
      @color = color
      @z = z
      @title = title
    end

    def draw(x, y)
      if @border
        draw_border(x, y)
      end
      if @background
        draw_background(x, y)
      end
      if @title
        draw_title(x, y)
      end
    end

    def draw_title(x_start, y_start)
      # centering text
      title_start = ((@width - @title.length) / 2) + x_start
      title_end = title_start + @title.length
      SpriteText.new(@title).draw(
        title_start.tiles,
        1.tile,
        1000
      )
      # line
      ((x_start + 1)...title_start).each do |x|
        $window.sprites[45].draw(
          x.tiles,
          1.tile,
          1000
        )
      end
      (title_end...(@width + x_start - 1)).each do |x|
        $window.sprites[45].draw(
          x.tiles,
          1.tile,
          1000
        )
      end
    end

    def draw_border(x, y)
      (y...@height).each do |tile_y|
        (x...@width).each do |tile_x|
          case
          when tile_y == 0 && tile_x == 0
            #upper left
            $window.sprites[201].draw(x.tiles + tile_x.tiles, y.tiles + tile_y.tiles, @z)
          when tile_y == 0 && tile_x == @width - 1
            #upper right
            $window.sprites[187].draw(x.tiles+ tile_x.tiles, y.tiles + tile_y.tiles, @z)
          when tile_y == @height - 1 && tile_x == 0
            #lower left
            $window.sprites[200].draw(x.tiles + tile_x.tiles, y.tiles + tile_y.tiles, @z)

          when (tile_y == @height - 1) && (tile_x == @width - 1)
            #lower right
            $window.sprites[188].draw(x.tiles + tile_x.tiles, y.tiles + tile_y.tiles, @z)
          when tile_y == 0
            #upper
            $window.sprites[205].draw(x.tiles+ tile_x.tiles, y.tiles + tile_y.tiles, @z)
          when tile_y == @height - 1
            #lower
            $window.sprites[205].draw(x.tiles+ tile_x.tiles, y.tiles + tile_y.tiles, @z)
          when tile_x == 0
            #left
            $window.sprites[186].draw(x.tiles+ tile_x.tiles, y.tiles + tile_y.tiles, @z)
          when tile_x == @width - 1
            #right
            $window.sprites[186].draw(x.tiles+ tile_x.tiles, y.tiles + tile_y.tiles, @z)
          end
        end
      end
    end

    def draw_background(x, y)
      Gosu.draw_rect(
        x,
        y,
        @width.tiles,
        @height.tiles,
        color,
        @z - 1
      )
    end

  end

end
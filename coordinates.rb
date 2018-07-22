class Coordinates
  attr_accessor :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def ==(other)
    self.class === other &&
      other.x == @x &&
      other.y == @y
  end

  def !=(other)
    !(self==(other))
  end

  alias eql? ==

  def hash
    [@x, @y].hash
  end

  def +(other)
    Coordinates.new(@x + other.x, @y + other.y)
  end

  def -(other)
    Coordinates.new(@x - other.x, @y - other.y)
  end

  def n
    Coordinates.new(@x, @y - 1)    
  end

  def ne
    Coordinates.new(@x + 1, @y - 1)
  end

  def e
    Coordinates.new(@x +1, @y)    
  end

  def se
    Coordinates.new(@x + 1, @y + 1)    
  end

  def s
    Coordinates.new(@x, @y + 1)    
  end

  def sw
    Coordinates.new(@x - 1, @y + 1)    
  end

  def w
    Coordinates.new(@x -1 , @y)    
  end

  def nw
    Coordinates.new(@x - 1, @y - 1)    
  end

  def neighbors
    [n, ne, e, se, s, sw, w, nw]
  end

  def closest_from_array(coordinate_array)
    closest_distance = nil
    closest = nil
    coordinate_array.each do |test_coordinates|
      distance = Coordinates.distance(self, test_coordinates)
      # Using Euclidian distance here makes targeting feel more natural
      closest_distance ||= distance
      if distance <= closest_distance
        closest_distance = distance
        closest = test_coordinates
      end
    end
    return closest.dup
    # Hmm... some odd consequences if I don't dup the returned coordinates--Why wouldn't you be able to share coordinates instances between objects?? the coordinates aren't being altered.
  end


  def Coordinates.tile_distance(c1, c2)
    x_diff = (c2.x - c1.x).abs
    y_diff = (c2.y - c1.y).abs
    return x_diff >= y_diff ? x_diff : y_diff
  end

  def Coordinates.relative_distance(c1, c2)
    (c2.x - c1.x)**2 + (c2.y - c1.y)**2
  end

  def Coordinates.distance(c1, c2)
    Math::sqrt((c2.x - c1.x)**2 + (c2.y - c1.y)**2)
  end

  def Coordinates.bresenhams_line(c1, c2)
    # Returns array of coordinates that form tile-quantized line between two coordinates
    coordinates_in_line = []
    x1, y1 = c1.x, c1.y
    x2, y2 = c2.x, c2.y
    steep = (y2 - y1).abs > (x2 - x1).abs
    if steep
      x1, y1 = y1, x1
      x2, y2 = y2, x2
    end

    if x1 > x2
      x1, x2 = x2, x1
      y1, y2 = y2, y1
    end

    dx = x2 - x1
    dy = (y2 - y1).abs
    error = dx / 2
    ystep = y1 < y2 ? 1 : -1

    y = y1
    x1.upto(x2) do |x|
      if steep
        coordinates_in_line << Coordinates.new(y, x)
      else
        coordinates_in_line << Coordinates.new(x, y)
      end
      error -= dy
      if error < 0
        y += ystep
        error += dx
      end
    end
    coordinates_in_line
  end


end
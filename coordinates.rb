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
    # Hmm... some odd consequences if I don't dup the returned coordinates--Why wouldn't you be able to share coordinate instances between objects??
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

end
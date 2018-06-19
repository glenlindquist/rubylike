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
      closest_distance ||= distance
      if distance <= closest_distance
        closest_distance = distance
        closest = test_coordinates
      end
    end
    return closest
  end

  def Coordinates.distance(c1, c2)
    Math::sqrt((c2.x - c1.x)**2 + (c2.y - c1.y)**2)
  end

end
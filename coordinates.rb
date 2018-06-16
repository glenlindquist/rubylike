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
    Coordinates.new(other.x + @x, other.y + @y)
  end

  def -(other)
    Coordinates.new(other.x - @x, other.y - @y)
  end

end
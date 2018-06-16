class Player
  attr_accessor :coordinates
  def initialize(coordinates = Coordinates.new(20, 15))
    @coordinates = coordinates
  end
end
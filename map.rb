class Map
  attr_accessor :tiles
  def initialize
    @tiles = {}
    (-100...100).each do |y|
      (-100...100).each do |x|
        coordinates = Coordinates.new(x,y)
        tile = Tile.new(coordinates, rand(10) > 7 ? 23 : rand(176..178))
        tile.map = self
        @tiles[coordinates] = tile
      end
    end
  end
end
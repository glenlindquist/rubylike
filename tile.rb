class Tile
  attr_reader :coordinates
  attr_accessor :type, :map

  def initialize(coordinates, type = 250)
    @coordinates = coordinates
    @type = type
  end



end
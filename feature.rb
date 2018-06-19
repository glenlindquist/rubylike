class Feature
  attr_reader :coordinates
  attr_accessor :type, :sprite_index, :fg_color
  def initialize(coordinates, type)
    @coordinates = coordinates
    @type = type
    @sprite_index = set_sprite
    @fg_color = set_fg_color
  end

  def set_sprite
    case type
    when "tree"
      23
    when "stump"
      22
    when "stone"
      7
    else
      @type = "tree"
      23
    end
  end

  def set_fg_color
    case type
    when "tree"
      0xff_15590C
    when "stump"
      0xff_634A1B
    when "stone"
      0xff_9DA1B0
    else
      @type = "tree"
      0xff_15590C
    end
  end
end
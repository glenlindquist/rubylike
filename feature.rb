class Feature
  attr_reader :coordinates, :full_condition
  attr_accessor :type, :sprite_index, :fg_color, :current_condition
  def initialize(coordinates, type)
    @coordinates = coordinates
    @type = type
    @sprite_index = set_sprite
    @fg_color = Feature.get_fg_color(@type)
    @full_condition = 100.0
    @current_condition = 100.0
  end

  def set_sprite
    case type
    when "tree"
      23
    when "log"
      22
    when "stone"
      7
    when "flower"
      15
    when "stick"
      rand < 0.5 ? 47 : 92
    when "shell"
      43
    else
      @type = "tree"
      23
    end
  end

  def set_fg_color
    case type
    when "tree"
      0xff_15590C
    when "log"
      0xff_634A1B
    when "stone"
      0xff_9DA1B0
    when "flower"
      0xff_ffaa00
    when "stick"
      0xff_634A1B
    when "shell"
      0xff_A3F7FF
    else
      @type = "tree"
      0xff_15590C
    end
  end

  def navigable?
    case type
    when "tree"
      false
    when "log"
      true
    when "stone"
      true
    when "flower"
      true
    when "stick"
      true
    when "shell"
      true
    else
      true
    end
  end

  def self.get_sprite(feature_type)
    case feature_type
    when "tree"
      23
    when "log"
      22
    when "stone"
      7
    when "flower"
      15
    when "stick"
      47
    when "shell"
      43
    else
      23
    end
  end

  def self.get_fg_color(feature_type)
    case feature_type
    when "tree"
      0xff_15590C
    when "log"
      0xff_634A1B
    when "stone"
      0xff_9DA1B0
    when "flower"
      0xff_ffaa00
    when "stick"
      0xff_634A1B
    when "shell"
      0xff_A3F7FF
    else
      0xff_15590C
    end
  end
end
class Tile
  attr_reader :coordinates
  attr_accessor :sprite_index, :map, :terrain

  def initialize(coordinates, terrain = "void")
    @coordinates = coordinates
    @terrain = terrain
    @sprite_index = pick_sprite
  end

  def screen_coordinates
    @coordinates + $window.camera.coordinates
  end

  def navigable?
    
    if $window.map.features.include?(@coordinates)
      return false if !$window.map.features[@coordinates].navigable?
    end
    case @terrain
    when "tree"
      false
    when "void"
      false
    when "water"
      false
    else
      true
    end
  end

  def pick_sprite
    case @terrain
    when "void"
      0
    when "grass"
      rand(176..178)
    when "water"
      247
    when "shallow_water"
      247  
    when "sand"
      177
    when "dirt"
      176
    when "tree"
      23
    when "rock"
      178
    else
      @terrain = "void"
      0
    end
  end

  def bg_color
    case @terrain
    when "void"
      0xff_ff0000
    when "grass"
      0xff_34BB37
    when "water"
      0xff_272CAB
    when "sand"
      0xff_EBC800
    when "dirt"
      0xff_634A1B
    when "tree"
      0xff_34BB37
    when "rock"
      0xff_4C4C41
    when "shallow_water"
      0xff_4486B5 
    else
      @terrain = "void"
      0xff_ff0000
    end
  end

  def fg_color
    case @terrain
    when "void"
      0xff_000000
    when "grass"
      0xff_15991D
    when "water"
      0xff_4486B5
    when "sand"
      0xff_BA8C00
    when "dirt"
      0xff_ffff00
    when "tree"
      0xff_006622
    when "rock"
      0xff_000000
    when "shallow_water"
      0xff_272CAB
    else
      @terrain = "void"
      0xff_000000
    end
  end

end
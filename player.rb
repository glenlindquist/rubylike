class Player
  attr_accessor :coordinates, :movement_cost, :selected_inventory_slot, :selector_active, :target, :beard_level, :last_shaved_at, :beard_threshold, :vision_radius
  attr_reader :inventory

  BEARD_GROWTH_RATE =  0.1 # 1.0 #

  def initialize(coordinates = Coordinates.new(20, 15))
    @coordinates = coordinates
    @movement_cost = 1
    @inventory = {
      1 => [],
      2 => [],
      3 => [],
      4 => [],
      5 => [],
      6 => [],
      7 => [],
      8 => [],
      9 => [],
      0 => []
    }
    @selected_inventory_slot = 1
    @target = nil
    @harvest_chance = 1
    @harvest_strength = 10

    @beard_level = 0
    @beard_threshold = 10
    @beard_threshold_increase = 10 + (0.1 * @beard_level)
    @last_shaved_at = 0

    @vision_radius = 10

    coordinates_in_vision.each do |coordinates|
      $window.map.tile_at(coordinates).known = true if $window.map.tile_at(coordinates)
    end
  end

  def update
    @beard_level = ($window.timer - @last_shaved_at) * BEARD_GROWTH_RATE
    grow_beard if @beard_level > @beard_threshold
  end

  def grow_beard
    @beard_threshold += @beard_threshold_increase
    elligible_cells = []

    $window.avatar_beard.each do |coordinates, growth|
      if growth < 3
        elligible_cells << coordinates
      end
    end

    if elligible_cells.length > 10
      new_growth_cell = elligible_cells[rand(elligible_cells.length - 1)]
      $window.avatar_beard[new_growth_cell] += 1
    else
      # To sprout new beard below:
      #we are a beard cell with a nil south neighbor we can grow a new cell
      elligible_cells = []
      $window.avatar_beard.each do |coordinates, growth|
        if coordinates.s != Coordinates.new(3,5) && # mouth
          coordinates.s != Coordinates.new(4,5) &&  # mouth
          ($window.avatar_beard[coordinates.s].nil? ||
          $window.avatar_beard[coordinates.s] < $window.avatar_beard[coordinates])

          elligible_cells << coordinates
        end
      end
      new_beard_cell = elligible_cells[rand(elligible_cells.length - 1)].s
      $window.avatar_beard[new_beard_cell] ||= 0
      $window.avatar_beard[new_beard_cell] += 1
    end
  end

  def screen_coordinates
    @coordinates - $window.camera.coordinates
  end

  # find nearest on map. Should be on screen...
  def find_nearest_feature(feature_type)
    feature_coordinates = []
    $window.map.features.each do |coordinates, feature|
      if feature.type == feature_type
        feature_coordinates << coordinates
      end
    end
    $window.map.features[@coordinates.closest_from_array(feature_coordinates)]
  end

  def add_to_inventory(feature_type)
    @inventory.each do |index, item|
      if item[0] == feature_type && item[1] < 99
        @inventory[index] = [item[0], item[1] + 1]
        return true
      elsif item.empty?
        @inventory[index] = [feature_type, 1]
        return true
      end
    end
    return false
    # No room in inventory, should alert player.
  end

  def remove_from_inventory(inventory_slot)
    return false if inventory[inventory_slot].empty?
    inventory[inventory_slot][1] -= 1
    inventory[inventory_slot] = [] if inventory[inventory_slot][1] == 0
    return true
  end

  def move_toward(other_coordinates)
    return false if Coordinates.tile_distance(@coordinates, other_coordinates) <= 1
    eligible_neighbors = []
    @coordinates.neighbors.each do |neighbor|
      if $window.map.tiles[neighbor].navigable?
        eligible_neighbors << neighbor
      end
    end
    @coordinates = other_coordinates.closest_from_array(eligible_neighbors)
    true
  end

  def harvest(feature_type)
    feature = find_nearest_feature(feature_type)
    @target = feature.coordinates.dup
    if !move_toward(@target)
      feature.current_condition -= @harvest_chance * @harvest_strength
      if feature.current_condition <= 0
        $window.map.features.delete(feature.coordinates)
        $window.meters.delete(feature.coordinates)
        $window.map.features[feature.coordinates] = Feature.new(feature.coordinates, "log")
        @target = nil
      else
        $window.meters[@target] = 
          feature.current_condition / feature.full_condition
      end
    end
  end
  
  def coordinates_in_vision
    coordinates = []
    ((@coordinates.y - @vision_radius + 1)...(@coordinates.y + @vision_radius)).each do |y|
      ((@coordinates.x - @vision_radius + 1)...(@coordinates.x + @vision_radius)).each do |x|
        coordinates << Coordinates.new(x,y)
      end
    end
    coordinates
  end

  def move(direction)
    case direction
    when "north"
      new_coordinates = @coordinates + Coordinates.new(0, -1)
      @coordinates = new_coordinates if $window.map.tile_at(new_coordinates).navigable?
    when "northeast"
      new_coordinates = @coordinates + Coordinates.new(1, -1)
      @coordinates = new_coordinates if $window.map.tile_at(new_coordinates).navigable?
    when "east"
      new_coordinates = @coordinates + Coordinates.new(1, 0)
      @coordinates = new_coordinates if $window.map.tile_at(new_coordinates).navigable?
    when "southeast"
      new_coordinates = @coordinates + Coordinates.new(1, 1)
      @coordinates = new_coordinates if $window.map.tile_at(new_coordinates).navigable?
    when "south"
      new_coordinates = @coordinates + Coordinates.new(0, 1)
      @coordinates = new_coordinates if $window.map.tile_at(new_coordinates).navigable?
    when "southwest"
      new_coordinates = @coordinates + Coordinates.new(-1, 1)
      @coordinates = new_coordinates if $window.map.tile_at(new_coordinates).navigable?
    when "west"
      new_coordinates = @coordinates + Coordinates.new(-1, 0)
      @coordinates = new_coordinates if $window.map.tile_at(new_coordinates).navigable?
    when "northwest"
      new_coordinates = @coordinates + Coordinates.new(-1, -1)
      @coordinates = new_coordinates if $window.map.tile_at(new_coordinates).navigable?
    end
    coordinates_in_vision.each do |coordinates|
      $window.map.tile_at(coordinates).known = true if $window.map.tile_at(coordinates)
    end
    $window.update_camera
  end
    

end
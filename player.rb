class Player
  attr_accessor :coordinates, :movement_cost, :selected_inventory_slot, :selector_active, :target
  attr_reader :inventory
  def initialize(coordinates = Coordinates.new(20, 15))
    @coordinates = coordinates
    @movement_cost = 10
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
    return if Coordinates.tile_distance(@coordinates, other_coordinates) <= 1
    eligible_neighbors = []
    @coordinates.neighbors.each do |neighbor|
      if $window.map.tiles[neighbor].navigable?
        eligible_neighbors << neighbor
      end
    end
    @coordinates = other_coordinates.closest_from_array(eligible_neighbors)
  end

end
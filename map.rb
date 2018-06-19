class Map
  # Land-generation Constants
  LAND_CHANCE = 0.5   # Initial chance to be land
  STEPS = 5          # Number of simulation steps
  DEATH_LIMIT = 3     # Lower means more land
  OVERPOP_LIMIT = 8   # Higher means more land
  BIRTH_LIMIT = 4     # Lower means more land

  # Feature-generation constants
  TREE_CHANCE = 0.10
  STUMP_CHANCE = 0.05
  STONE_CHANCE = 0.05
  
  attr_accessor :tiles, :features
  def initialize
    @tiles = {}
    @features = {}
    land_map = generate_land
    feature_map = generate_features(land_map)
    assign_tiles(land_map)
    #assign_features(feature_map)
  end

  def generate_land
    generation_tiles = {}
    (-100...100).each do |y|
      (-100...100).each do |x|
        coordinates = Coordinates.new(x,y)
        generation_tiles[coordinates] = rand > LAND_CHANCE ? 0 : 1
      end
    end
    land_map = simulation_step(generation_tiles, STEPS)
    generate_sand(land_map)
    generate_shallow_water(land_map)
  end

  def simulation_step(previous_tiles, steps_remaining)
    new_tiles = {}
    previous_tiles.each do |coordinates, value|
      neighbors = [
        previous_tiles[coordinates + Coordinates.new(0, -1)],  #n
        previous_tiles[coordinates + Coordinates.new(1, -1)],  #ne
        previous_tiles[coordinates + Coordinates.new(1, 0)],   #e
        previous_tiles[coordinates + Coordinates.new(1, 1)],   #se
        previous_tiles[coordinates + Coordinates.new(0, 1)],   #s
        previous_tiles[coordinates + Coordinates.new(-1, 1)],  #sw
        previous_tiles[coordinates + Coordinates.new(-1, 0)],  #w
        previous_tiles[coordinates + Coordinates.new(-1, -1)]  #nw
      ]
      count = neighbors.compact.sum
      if value == 1
        if count < DEATH_LIMIT || count > OVERPOP_LIMIT
          new_tiles[coordinates] = 0
        else
          new_tiles[coordinates] = 1
        end
      else
        if count > BIRTH_LIMIT
          new_tiles[coordinates] = 1
        else
          new_tiles[coordinates] = 0
        end
      end
    end

    return new_tiles if steps_remaining == 0
    simulation_step(new_tiles, steps_remaining - 1)
  end

  def generate_sand(land_map)
    land_map.each do |coordinates, value|
      if value == 1
        neighbors = [
          land_map[coordinates + Coordinates.new(0, -1)],  #n
          land_map[coordinates + Coordinates.new(1, -1)],  #ne
          land_map[coordinates + Coordinates.new(1, 0)],   #e
          land_map[coordinates + Coordinates.new(1, 1)],   #se
          land_map[coordinates + Coordinates.new(0, 1)],   #s
          land_map[coordinates + Coordinates.new(-1, 1)],  #sw
          land_map[coordinates + Coordinates.new(-1, 0)],  #w
          land_map[coordinates + Coordinates.new(-1, -1)] #nw
        ]
        if neighbors.include?(0) # Touches water
          land_map[coordinates] = 2
        end
      end
    end
    land_map
  end

  def generate_shallow_water(land_map)
    land_map.each do |coordinates, value|
      if value == 0
        neighbors = [
          land_map[coordinates + Coordinates.new(0, -1)],  #n
          land_map[coordinates + Coordinates.new(1, -1)],  #ne
          land_map[coordinates + Coordinates.new(1, 0)],   #e
          land_map[coordinates + Coordinates.new(1, 1)],   #se
          land_map[coordinates + Coordinates.new(0, 1)],   #s
          land_map[coordinates + Coordinates.new(-1, 1)],  #sw
          land_map[coordinates + Coordinates.new(-1, 0)],  #w
          land_map[coordinates + Coordinates.new(-1, -1)] #nw
        ]
        if neighbors.include?(2) # Touches sand
          land_map[coordinates] = 3
        end
      end
    end
    land_map
  end

  def generate_features(land_map)
    feature_map = {}
    land_map.each do |coordinates, value|
      if value == 1 # Grass
        if TREE_CHANCE > rand
          @features[coordinates] = Feature.new(coordinates, "tree")
        end
        if STUMP_CHANCE > rand
          @features[coordinates] = Feature.new(coordinates, "stump")
        end
        if STONE_CHANCE > rand
          @features[coordinates] = Feature.new(coordinates, "stone")
        end
      end
    end
    feature_map
  end

  def assign_tiles(generated_map)
    generated_map.each do |coordinates, value|
      case value
      when 0
        tile = Tile.new(coordinates, "water")
      when 1
        tile = Tile.new(coordinates, "grass")
      when 2
        tile = Tile.new(coordinates, "sand")
      when 3
        tile = Tile.new(coordinates, "shallow_water")
      else
        tile = Tile.new(coordinates, "grass")
      end
      @tiles[coordinates] = tile 
    end
  end

  def tile_at(coordinates)
    @tiles[coordinates]
  end

end

class Map

  # Land-generation Constants
  LOW_RES_LAND_CHANCE = 0.55
  LOW_RES_STEPS = 5
  DOWNSAMPLE_BY = 0.2

  LAND_CHANCE = 0.55   # Initial chance to be land
  STEPS = 10          # Number of simulation steps
  DEATH_LIMIT = 4     # Lower means more land
  OVERPOP_LIMIT = 8   # Higher means more land
  BIRTH_LIMIT = 4     # Lower means more land
  MUTATION_CHANCE = 0.25 #Flip-flop chance after low-res generation

  # Feature-generation constants
  TREE_CHANCE = 0.10
  STUMP_CHANCE = 0.0005
  STONE_CHANCE = 0.02
  FLOWER_CHANCE = 0.02

  #Minimap
  MINIMAP_DESIRED_WIDTH = 18.0  # MUST BE DECIMAL
  MINIMAP_SAMPLE_RESOLUTION = 200 / MINIMAP_DESIRED_WIDTH # n x n world tiles make 1 minimap tile
  
  attr_accessor :tiles, :features, :minimap
  def initialize(map_tile_width = 200, map_tile_height = 200)

    # ensure that numbers will play nice
    if (map_tile_width * DOWNSAMPLE_BY / 2) % 1 == 0
      @map_tile_width = map_tile_width
    else
      @map_tile_width = 200
    end
    if (map_tile_height * DOWNSAMPLE_BY / 2) % 1 == 0
      @map_tile_height = map_tile_height
    else
      @map_tile_height = 200
    end

    @features = {}
    #low res gives bigger lakes, less random puddles.
    low_res_land_map = generate_low_res_land_map
    land_map = generate_land(low_res_land_map)
    feature_map = generate_features(land_map)
    @tiles = assign_tiles(land_map)
    @minimap = self.downsample
    
    #assign_features(feature_map)
  end

  def generate_low_res_land_map
    low_res_generation_tiles = {}
    (-(@map_tile_height * DOWNSAMPLE_BY / 2).to_i..(@map_tile_height * DOWNSAMPLE_BY / 2).to_i).each do |y|
      (-(@map_tile_width * DOWNSAMPLE_BY / 2).to_i..(@map_tile_width * DOWNSAMPLE_BY / 2).to_i).each do |x|
        coordinates = Coordinates.new(x,y)
        low_res_generation_tiles[coordinates] = rand > LOW_RES_LAND_CHANCE ? 0 : 1
      end
    end
    low_res_generation_tiles = simulation_step(low_res_generation_tiles, LOW_RES_STEPS)
  end

  def generate_land(low_res_generation_tiles)
    generation_tiles = {}
    (-(@map_tile_height / 2)..(@map_tile_height / 2)).each do |y|
      (-(@map_tile_width / 2)..(@map_tile_width / 2)).each do |x|
        coordinates = Coordinates.new(x,y)
        #old method
        #generation_tiles[coordinates] = rand > LAND_CHANCE ? 0 : 1
        #new method (based on low_res)
        generation_tiles[coordinates] = low_res_generation_tiles[Coordinates.new((coordinates.x * DOWNSAMPLE_BY).floor, (coordinates.y * DOWNSAMPLE_BY).floor)]

        #random mutation
        generation_tiles[coordinates] = rand < MUTATION_CHANCE ? generation_tiles[coordinates] ^ 1 : generation_tiles[coordinates]
      end
    end
    make_edge_water(generation_tiles, 5)
    land_map = simulation_step(generation_tiles, STEPS)
    make_edge_water(land_map, 3)
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

  def make_edge_water(land_map, edge_buffer = 5)
    land_map.each do |coordinates, type|
      if coordinates.y < -(@map_tile_height / 2) + edge_buffer ||
         coordinates.y >  (@map_tile_height / 2) - edge_buffer ||
         coordinates.x < -(@map_tile_width / 2) + edge_buffer ||
         coordinates.x >  (@map_tile_width / 2) - edge_buffer

         land_map[coordinates] = 0
      end
    end
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
        if FLOWER_CHANCE > rand
          @features[coordinates] = Feature.new(coordinates, "flower")
        end
      end
    end
    feature_map
  end

  def assign_tiles(generated_map)
    temp_tiles = {}
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
      temp_tiles[coordinates] = tile 
    end
    return temp_tiles
  end

  def tile_at(coordinates)
    @tiles[coordinates]
  end

  def find_solid_ground(closest_to = Coordinates.new(0,0))
    return closest_to if tile_at(closest_to).navigable?
    solid_ground = []
    @tiles.each do |coordinates, tile|
      if tile.navigable?
        solid_ground.push(coordinates)
      end
    end
    
    return closest_to if solid_ground.empty?
    return closest_to.closest_from_array(solid_ground)
  end

  def downsample
    #to generate minimap
    sample_tiles = {}

    (-(@map_tile_height / 2)...(@map_tile_height / 2)).each do |y|
      (-(@map_tile_width / 2)...(@map_tile_width / 2)).each do |x|
        coordinates = Coordinates.new(x,y)
        sample_coordinates = Coordinates.new(
          ((x + @map_tile_width / 2)  / MINIMAP_SAMPLE_RESOLUTION).floor,
          ((y + @map_tile_height / 2) / MINIMAP_SAMPLE_RESOLUTION).floor
        )
        sample_tiles[sample_coordinates] ||= 0
        if @tiles[coordinates].terrain == "water" || @tiles[coordinates].terrain == "shallow_water"
          # pass
        else
          sample_tiles[sample_coordinates] += 1
        end

      end
    end
    sample_tiles.each do |coordinates, total|
      if total > (MINIMAP_SAMPLE_RESOLUTION**2 / 2)
        # more than half are land
        sample_tiles[coordinates] = Tile.new(coordinates, "grass")
      else
        sample_tiles[coordinates] = Tile.new(coordinates, "water")
      end
    end
    sample_tiles
  end

  def world_coordinates_to_minimap_coordinates(world_coordinates)
    new_coordinates = Coordinates.new(
      ((world_coordinates.x + @map_tile_width / 2)  / MINIMAP_SAMPLE_RESOLUTION).floor,
      ((world_coordinates.y + @map_tile_height / 2) / MINIMAP_SAMPLE_RESOLUTION).floor
    )
  end
end

class Player
  attr_accessor :coordinates
  def initialize(coordinates = Coordinates.new(20, 15))
    @coordinates = coordinates
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
end
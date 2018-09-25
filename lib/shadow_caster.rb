class ShadowCaster

  def compute_fov_with_shadows(x, y, radius)
    (0..7).each do |octant|
      compute_fov_for_octant(octant, radius)
    end
    # compute_fov_for_octant(0, radius)
  end

  def compute_fov_for_octant(octant, radius)
    queue = []
    queue << ColumnPortion.new(
      0, 
      DirectionVector.new(1,1), 
      DirectionVector.new(1,0),
    )
    while queue.count != 0
      current = queue.shift
      if current.x >= radius
        next
      end
      compute_fov_for_column_portion(
        octant,
        current.x,
        current.top_vector,
        current.bottom_vector,
        radius,
        queue
      )
    end
  end

  def compute_fov_for_column_portion(
    octant,
    x,
    top_vector,
    bottom_vector,
    radius,
    queue
  )
    # To find top of column to begin check
    quotient = ((2 * x + 1) * top_vector.y) / (1.0 * 2 * top_vector.x)
    quotient = quotient.floor
    remainder = ((2 * x + 1) * top_vector.y) % (1.0 * 2 * top_vector.x)
    remainder = remainder.floor
    if x == 0
      top_y = 0
    else
      if remainder <= top_vector.x
        top_y = quotient
      else
        top_y = quotient + 1
      end
    end

    # To find bottom of column to end check

    quotient = ((2 * x - 1) * bottom_vector.y) / (1.0 * 2 * bottom_vector.x)
    quotient = quotient.floor
    remainder = ((2 * x - 1) * bottom_vector.y) % (1.0 * 2 * bottom_vector.x)
    remainder = remainder.floor
    if x == 0
      bottom_y = 0
    else
      if remainder < bottom_vector.x
        bottom_y = quotient
      else
        bottom_y = quotient + 1
      end
    end

    was_last_cell_opaque = nil
    top_y.downto(bottom_y).each do |y|
      in_radius = is_in_radius?(x,y,radius)
      if in_radius
        set_as_visible(x, y, octant)
      end
      current_is_opaque = !in_radius || is_opaque(x, y, octant)
      if !was_last_cell_opaque.nil?
        if current_is_opaque
          if !was_last_cell_opaque
            #transition from transparent to opaque
            queue << ColumnPortion.new(
              x + 1,
              top_vector,
              DirectionVector.new(x * 2 - 1, y * 2 + 1)
            )
          end
        elsif was_last_cell_opaque
          #transition from opaque to transparent
          top_vector = DirectionVector.new(x * 2 + 1, y * 2 + 1)
        end
      end
      was_last_cell_opaque = current_is_opaque
    end
    if (was_last_cell_opaque != nil && !was_last_cell_opaque)
      queue << ColumnPortion.new(
        x + 1,
        top_vector,
        bottom_vector
      )
    end
  end

  def is_opaque(x, y, octant)
   
    case octant
    when 0
      x, y = x, y
    when 1
      x, y = y, x
    when 2
      x, y = -y, x
    when 3
      x, y = -x, y
    when 4
      x, y = -x, -y
    when 5
      x, y = -y, -x
    when 6
      x, y = y, -x
    when 7
      x, y = x, -y
    end
    x = x + $window.player.coordinates.x
    y = $window.player.coordinates.y - y
    $window.map.tile_at(Coordinates.new(x,y)).opaque?
  end

  def set_as_visible(x, y, octant)
    case octant
    when 0
      x, y = x, y
    when 1
      x, y = y, x
    when 2
      x, y = -y, x
    when 3
      x, y = -x, y
    when 4
      x, y = -x, -y
    when 5
      x, y = -y, -x
    when 6
      x, y = y, -x
    when 7
      x, y = x, -y
    end
    x = x + $window.player.coordinates.x
    y = $window.player.coordinates.y - y
    $window.map.tile_at(Coordinates.new(x,y)).known = true
    $window.map.tile_at(Coordinates.new(x,y)).visible = true
  end

  def is_in_radius?(x, y, radius)
    if x > radius || y > radius
      return false
    else
      return true
    end
  end

end

class DirectionVector < Struct.new(:x, :y)
end

class ColumnPortion < Struct.new(:x, :top_vector, :bottom_vector)
end
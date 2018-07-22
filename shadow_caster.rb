class ShadowCaster
  def compute_fov_with_shadows(x, y, radius)

  end

  def compute_fov_for_octant_zero(radius)
    queue = []
    queue << ColumnPortion.new(
      0, 
      DirectionVector.new(1,1), 
      DirectionVector.new(1,0),
      &is_opaque
      &set_as_visible
    )
    while queue.count != 0
      current = queue.shift
      if current.x >= radius
        next
      end
      compute_fov_for_column_portion(
        current.x,
        current.top_vector,
        current.bottom_vector,
        radius,
        queue
      )
    end
  end

  def compute_fov_for_column_portion(
    x,
    top_vector,
    bottom_vector,
    radius,
    queue
  )
    # To find top of column to begin check
    quotient = 1.0 * ((2 * x + 1) * top_vector.y) / (2 * top_vector.x)
    remainder = 1.0 * ((2 * x + 1) * top_vector.y) % (2 * top_vector.x)
    if remainder <= top_vector.x
      top_y = quotient
    else
      top_y = quotient + 1
    end

    # To find bottom of column to end check
    quotient = 1.0 * ((2 * x - 1) * bottom_vector.y) / (2 * bottom_vector.x)
    remainder = 1.0 * ((2 * x - 1) * bottom_vector.y) % (2 * bottom_vector.x)
    if remainder <= bottom_vector.x
      bottom_y = quotient
    else
      bottom_y = quotient + 1
    end

    was_last_cell_opaque = nil
    top_y.downto(bottom_y).each do |y|
      in_radius = is_in_radius?(x,y,radius)
      if in_radius
        set_as_visible(x, y)
      end
      current_is_opaque = !in_radius || is_opaque?(x,y)
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

  def is_in_radius?(x, y, radius)

  end

  def set_as_visible(x, y)

  end

  

end

class DirectionVector < Struct.new(:x, :y)
end

class ColumnPortion < Struct.new(:x, :top_vector, :bottom_vector)
end
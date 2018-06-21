class SpriteText
  def initialize(text)
    tile_size = MainWindow::TILE_SIZE
    sprites = $window.sprites
    @sprite_array = []
    @dictionary = SpriteText.define_dictionary
    text.split("").each do |char|
      @dictionary[char] ||= 63
      @sprite_array << sprites[@dictionary[char]]
    end
  end

  def draw(x, y, z = 0, scale_x = 1, scale_y = 1, color = 0xff_FFFFFF)
    @sprite_array.each_with_index do |sprite, index|
      sprite.draw(x + index * MainWindow::TILE_SIZE, y, z, scale_x, scale_y, color)
    end
  end

  def self.define_dictionary
    # corresponds with spritesheet
    dict = {
      ' ' => 32,
      '!' => 33,
      '"' => 34,
      '#' => 35,
      '$' => 36,
      '%' => 37,
      '&' => 38,
      "'" => 39,
      '(' => 40,
      ')' => 41,
      ',' => 44,
      '-' => 45,
      '.' => 46,
      '/' => 47,
      ':' => 58,
      ';' => 59,
      '<' => 60,
      '>' => 62,
      '?' => 63,
      '@' => 64,
      '[' => 91,
      ']' => 93,
      '^' => 94,
      '_' => 95,
      '`' => 96,
      '{' => 123,
      '|' => 124,
      '}' => 125,
      '~' => 126
    }
    (0..9).to_a.each do |num|
      dict[num.to_s] = 48 + num
    end
    ('a'..'z').to_a.each_with_index do |letter, index|
      dict[letter] = 97 + index
    end
    ('A'..'Z').to_a.each_with_index do |letter, index|
      dict[letter] = 65 + index
    end
    dict
  end
end

# Need to add support for spaces and punctuation
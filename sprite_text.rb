class SpriteText
  def initialize(text)
    tile_size = MainWindow::TILE_SIZE
    sprites = $window.sprites
    @sprite_array = []
    @dictionary = SpriteText.define_dictionary
    text.split("").each do |char|
      @sprite_array << sprites[@dictionary[char]]
    end
  end

  def draw(x, y, z)
    @sprite_array.each_with_index do |sprite, index|
      sprite.draw(x + index * MainWindow::TILE_SIZE, y, z)
    end
  end

  def self.define_dictionary
    # corresponds with sprite file
    dict = {}
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
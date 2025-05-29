CLOTH_TYPES = (ENV['CLOTH_TYPES'] ? ENV['CLOTH_TYPES'].split(',').map(&:strip) : %w[
  Jeans Swimsuit Blouse Cardigan Dress Skirt Bodysuit Halterneck
  Jacket Shorts T-shirt Boot Hat Hoodie Sweater Vest Bathrobe Pants PoloShirt Shirt
]).freeze

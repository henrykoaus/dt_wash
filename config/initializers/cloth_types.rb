CLOTH_TYPES = ENV.fetch('CLOTH_TYPES', %w[
    Jeans Swimsuit Blouse Cardigan Dress Skirt Bodysuit Halterneck
    Jacket Shorts T-shirt Boot Hat Hoodie Sweater Vest Bathrobe Pants Polo\ shirt Shirt
  ].to_a).split(',').map(&:strip).freeze

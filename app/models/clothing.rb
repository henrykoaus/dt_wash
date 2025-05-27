class Clothing < ApplicationRecord
  belongs_to :order, optional: true
  has_one_attached :photo

  validates :cloth_type, inclusion: {
    in: CLOTH_TYPES,
    message: "must be one of type: #{CLOTH_TYPES.join(', ')}"
  }
  # validates :color, inclusion: {
  #   in: COLORS,
  #   message: "must be one of color: #{COLORS.join(', ')}"
  # }
end

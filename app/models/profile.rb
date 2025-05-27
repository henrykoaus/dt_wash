class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :photo

  geocoded_by :address
  after_validation :geocode

  after_create :attach_default_profile_photo

  private

  def attach_default_profile_photo
    photo.attach(io: File.open(Rails.root.join('app', 'assets', 'images', 'default_profile_photo.png')), filename: 'default_profile_photo.png', content_type: 'image/png')
  end
end

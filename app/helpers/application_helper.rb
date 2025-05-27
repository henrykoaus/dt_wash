module ApplicationHelper
  def random_loading_image
    images = Dir.glob(Rails.root.join('app/assets/images/loading/*'))
    image_path = images.sample
    image_path.sub(Rails.root.join('app/assets/images').to_s + '/', '')
  end
end

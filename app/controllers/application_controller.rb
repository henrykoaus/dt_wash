class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  include Pundit::Authorization

  # Pundit: allow-list approach
  after_action :verify_authorized, unless: :skip_pundit?
  after_action :verify_policy_scoped, unless: :skip_pundit?

  # Uncomment when you *really understand* Pundit!
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(root_path)
  end

  def new
    build_resource
    resource.build_profile
    super
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :role, profile_attributes: [:photo]])
  end

  def build_resource(hash = {})
    super.tap do |user|
      if params.dig(:user, :profile_attributes, :photo)
        avatar_name = params[:user][:profile_attributes][:photo]
        avatar_path = Rails.root.join('app/assets/images/avatars', avatar_name)

        if File.exist?(avatar_path)
          user.profile.photo.attach(
            io: File.open(avatar_path),
            filename: avatar_name,
            content_type: 'image/png'
          )
        end
      end
    end
  end

  private

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end
end

class ProfilesController < ApplicationController
  before_action :set_profile, only: %i[ show edit update destroy ]
  skip_after_action :verify_policy_scoped, only: %i[ show edit update destroy ]
  skip_after_action :verify_authorized, only: %i[ show edit update destroy ]

  def index
    @profiles = policy_scope(Profile)
  end

  def show
    authorize @profile
  end

  def edit
    authorize @profile
  end

  def create
    @profile = Profile.new(profile_params)
    authorize @profile

    if @profile.save
      redirect_to @profile, notice: "Profile was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @profile
    if @profile.update(profile_params)
      redirect_to @profile, notice: "Profile was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @profile
    @profile.destroy!
    redirect_to tests_url, notice: "Profile was successfully destroyed.", status: :see_other
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end

  def profile_params
    params.require(:profile).permit(:address, :photo)
  end
end

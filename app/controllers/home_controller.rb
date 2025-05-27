class HomeController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  def index
    render "home/landing" and return if current_user.nil?
    if current_user.role == "customer"
      render "home/customer"
    elsif current_user.role == "merchant"
      render "home/merchant"
    end
  end
end

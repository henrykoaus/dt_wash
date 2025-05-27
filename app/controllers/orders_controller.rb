require 'httparty'

class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :edit, :confirm, :progress, :update, :destroy]
  skip_after_action :verify_policy_scoped, only: [:index, :accepted_orders, :pick_up_orders, :show, :edit, :confirm, :progress, :new, :create, :update, :destroy]
  skip_after_action :verify_authorized, only: [:index, :accepted_orders, :pick_up_orders, :show, :edit, :confirm, :progress, :new, :create, :update, :destroy]

  def index
    if current_user.customer?
      @orders = policy_scope(Order).where(customer_id: current_user.id).page(params[:page]).per(2)
    else
      redirect_to pick_up_orders_orders_path
    end
  end

  def accepted_orders
    accepted_statuses = {
      "assigned_to_merchant" => 1,
      "confirm_with_merchant" => 2,
      "collected_to_store" => 3,
      "In_process_washing" => 4,
      "ready_to_pickup" => 5
    }
    @accepted_orders = policy_scope(Order).where(merchant_id: current_user.id)
    if params[:status].present? && accepted_statuses.key?(params[:status].to_s)
      @accepted_orders = @accepted_orders.where(status: accepted_statuses[params[:status]])
    else
      @accepted_orders = @accepted_orders.where(status: accepted_statuses.values)
    end
  end

  def pick_up_orders
    unless current_user.profile.latitude.present? && current_user.profile.longitude.present?
      redirect_to profile_path(current_user.profile.id), alert: "You need to add your address before picking up orders" and return
    end

    orders = get_order_by_distance(Order.where(status: 0),20)
    @pick_up_orders = Kaminari.paginate_array(orders).page(params[:page]).per(2)
    @markers = make_map_add_user(make_map(@pick_up_orders))
    @map_center = get_map_center_by_user
  end

  def show
    @order = Order.find(params[:id])
    authorize @order

    accepted_statuses = %w[assigned_to_merchant confirm_with_merchant collected_to_store In_process_washing ready_to_pickup]

    if @order.status == "created_by_user"
        @markers = make_map([@order])
    elsif accepted_statuses.include?(@order.status.to_s)
      if current_user.role == "merchant"
        @markers = make_map_add_user(make_map([@order]))
      else
        @markers = make_map_add_order_merchant(make_map([@order]),@order)
      end
    end
    @map_center = {
      lat: @order.latitude,
      lon: @order.longitude
    }.compact
  end

  def confirm
    authorize @order
    if @order.created_by_user?
      @order.update(status: :assigned_to_merchant, merchant_id: current_user.id)
      redirect_to @order, notice: "Order confirmed!"
    else
      redirect_to @order, alert: "Cannot confirm this order."
    end
  end

  def progress
    authorize @order
    if @order.ready_to_pickup?
      redirect_to @order, alert: "Order is already completed and cannot progress further."
    elsif @order.status.in?(%w[assigned_to_merchant confirm_with_merchant collected_to_store In_process_washing])
      @order.update(status: Order.statuses.keys[@order.status_before_type_cast + 1])
      redirect_to @order, notice: "Order progressed to the next stage!"
    else
      redirect_to @order, alert: "Cannot progress further."
    end
  end

  def new
    @order = current_user.orders_as_customer.new
    authorize @order
  end

  def create
    @order = current_user.orders_as_customer.new(order_params)
    @order.status = 0
    authorize @order
    if @order.save
      redirect_to @order, notice: 'Order created successfully'
    else
      redirect_to new_order_path, alert: "permitted params: #{order_params.inspect}"
    end
  end

  def edit
    authorize @order
  end

  def update
    ActiveRecord::Base.transaction do
      # Ensure clothings_attributes is an array
      clothing_attributes = order_params[:clothings_attributes].values

      # Get the IDs of the clothings included in the order_params
      clothing_ids = clothing_attributes.map { |attr| attr[:id].to_i }

      # Remove clothings not included in the order_params
      @order.clothings.where.not(id: clothing_ids).destroy_all

      # Update the order with the new parameters
      if @order.update(order_params)
        respond_to do |format|
          format.html { redirect_to @order, notice: "Order was successfully updated." }
          format.json { render :show, status: :ok, location: @order }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: 422 }
          format.json { render json: @order.errors, status: 422 }
        end
      end
    end
  end

  def destroy
    authorize @order
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: 'Order was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
    authorize @order
  end

  def order_params
    params.require(:order).permit(
      :address,
      :notes,
      :total_price,
      clothings_attributes: [  # Permits nested attributes for clothings
        :cloth_type,
        :color,
        :photo,
        :price,
        :id,
        :_destroy  # Only include if you need deletion capability
      ]
    )
  end

  def make_map(orders)
    orders.map do |order|
      {
        lat: order.latitude,
        lng: order.longitude,
        info_window_html: render_to_string(partial: "info_window", locals: { order: order }),
        marker_html: render_to_string(partial: "marker", locals: { order: order })
      }
    end
  end

  def make_map_add_user(makers)
    makers << {
      lat: current_user.profile.latitude,
      lng: current_user.profile.longitude,
      info_window_html: render_to_string(partial: "info_window", locals: { order: nil, merchant: current_user }),
      marker_html: render_to_string(partial: "marker", locals: { order: nil, merchant: current_user })
    }
    makers
  end

  def make_map_add_order_merchant(makers, order)
    makers << {
      lat: order.merchant.profile.latitude,
      lng: order.merchant.profile.longitude,
      info_window_html: render_to_string(partial: "info_window", locals: { order: nil, merchant: order.merchant }),
      marker_html: render_to_string(partial: "marker", locals: { order: nil, merchant: order.merchant })
    }
    makers
  end

  def get_order_by_distance(orders, target_distance)
    user_coordinates = {
      lat: current_user.profile.latitude,
      lon: current_user.profile.longitude
    }
    orders.select do |order|
      order_coordinates = {
        lat: order.latitude,
        lon: order.longitude
      }
      # next unless order_coordinates

      distance = calculate_distance(user_coordinates[:lat], user_coordinates[:lon], order_coordinates[:lat], order_coordinates[:lon])
      if distance < target_distance
        order.distance = distance
        true
      else
        false
      end
    end
  end

  def get_map_center_by_user
    {
      lat: current_user.profile.latitude,
      lon: current_user.profile.longitude
    }.compact
  end

  def calculate_distance(lat1, lon1, lat2, lon2)
    r = 6371 # Radius of the Earth in km
    d_lat = (lat2 - lat1) * Math::PI / 180
    d_lon = (lon2 - lon1) * Math::PI / 180
    a = Math.sin(d_lat / 2) * Math.sin(d_lat / 2) +
      Math.cos(lat1 * Math::PI / 180) * Math.cos(lat2 * Math::PI / 180) *
        Math.sin(d_lon / 2) * Math.sin(d_lon / 2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    r * c
  end
end

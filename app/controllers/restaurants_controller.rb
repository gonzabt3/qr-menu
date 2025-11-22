# frozen_string_literal: true

class RestaurantsController < ApplicationController
  before_action :set_restaurant, only: %i[show update destroy]
  before_action :authorize
  before_action :authorize_restaurant_owner, only: %i[update destroy]

  # GET /restaurants
  def index
    # Si es admin, mostrar todos los restaurantes
    # Si es usuario normal, solo mostrar sus restaurantes
    if is_admin_user?
      @restaurants = Restaurant.all.includes(:user)
      render json: @restaurants.map { |r|
        {
          id: r.id,
          name: r.name,
          address: r.address,
          phone: r.phone,
          email: r.email,
          website: r.website,
          instagram: r.instagram,
          description: r.description,
          status: 'active', # Campo por defecto ya que no existe en la BD
          createdAt: r.created_at.iso8601,
          owner: {
            id: r.user&.id,
            email: r.user&.email,
            name: r.user&.name
          }
        }
      }
    else
      @restaurants = current_user.restaurants
      render json: @restaurants
    end
  end

  # GET /users/:user_id/restaurants
  def index_by_email
    @user = User.find_by(email: params[:id])
    if @user
      @restaurants = @user.restaurants
      render json: @restaurants
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  # GET /restaurants/:id
  def show
    render json: @restaurant
  end

  # POST /restaurants
  def create
    @restaurant = current_user.restaurants.build(restaurant_params)

    if @restaurant.save
      render json: @restaurant, status: :created
    else
      if @restaurant.errors[:name].include?("has already been taken")
        render json: { error: "Restaurant name must be unique" }, status: :unprocessable_entity
      else
        render json: @restaurant.errors, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /restaurants/:id
  def update
    if @restaurant.update(restaurant_params)
      render json: @restaurant
    else
      render json: @restaurant.errors, status: :unprocessable_entity
    end
  end

  # DELETE /restaurants/:id
  def destroy
    @restaurant.destroy
  end

  private

  def is_admin_user?
    admin_emails = ENV['ADMIN_EMAILS']&.split(',')&.map(&:strip)&.map(&:downcase) || []
    current_user&.email&.downcase.in?(admin_emails)
  end

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
  end

  def restaurant_params
    params.require(:restaurant).permit(:name, :address, :phone, :email, :website, :instagram, :description)
  end

  def authorize_restaurant_owner
    return if @restaurant.user == current_user

    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end
end

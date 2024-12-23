class RestaurantsController < ApplicationController
  before_action :set_restaurant, only: [:show, :update, :destroy]
  before_action :authorize

  # GET /restaurants
  def index
    @restaurants = current_user.restaurants
    render json: @restaurants
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
      render json: @restaurant.errors, status: :unprocessable_entity
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

  def set_restaurant
    @restaurant = current_user.restaurants.find(params[:id])
  end

  def restaurant_params
    params.require(:restaurant).permit(:name, :address, :phone, :email, :website, :instagram, :description)
  end
end

# frozen_string_literal: true

# app/controllers/menus_controller.rb
class MenusController < ApplicationController
  before_action :set_restaurant, except: %i[show_by_name show_by_restaurant_id]
  before_action :set_menu, only: %i[show update destroy set_favorite]
  before_action :authorize, except: %i[show_by_name show_by_restaurant_id]
  before_action :authorize_restaurant_owner, only: %i[create update destroy set_favorite],
                                             except: %i[show_by_name show_by_restaurant_id]

  # GET /restaurants/:restaurant_id/menus
  def index
    @menus = @restaurant.menus
    render json: @menus
  end

  # GET /restaurants/:restaurant_id/menus/:id
  def show
    render json: @menu
  end

  # GET /menus/:id
  def show_by_restaurant_id
    restaurant = Restaurant.find_by(id: params[:id])

    if restaurant && restaurant.user.subscribed
      @menu = restaurant.menus.includes(sections: :products).where(favorite: true).first || restaurant.menus.includes(sections: :products).first
      if @menu
        render json: @menu.as_json(include: { sections: { include: :products } }).merge(restaurantName: restaurant.name)
      else
        render json: { error: 'Menu not found' },
               status: :not_found
      end
    else
      render json: { error: 'Restaurant not found' }, status: :not_found
    end
  end

  # GET /menus/by_name/:name
  def show_by_name
    restaurant = Restaurant.find_by(name: params[:name])
    if restaurant && restaurant.user.subscribed
      @menu = restaurant.menus.includes(sections: :products).where(favorite: true).first || restaurant.menus.includes(sections: :products).first
      if @menu
        render json: @menu.as_json(include: { sections: { include: :products } }).merge(restaurantName: restaurant.name)
      else
        render json: { error: 'Menu not found' },
               status: :not_found
      end
    else
      render json: { error: 'Restaurant not found' }, status: :not_found
    end
  end

  # GET /menus/:id/fullData
  def full_data
    render json: @menu.as_json(include: { sections: { include: :products } })
  end

  # POST /restaurants/:restaurant_id/menus
  def create
    @menu = @restaurant.menus.build(menu_params)
    @menu.favorite = true if @restaurant.menus.count.zero?

    if @menu.save
      render json: @menu, status: :created
    else
      render json: @menu.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /restaurants/:restaurant_id/menus/:id
  def update
    if @menu.update(menu_params)
      render json: @menu
    else
      render json: @menu.errors, status: :unprocessable_entity
    end
  end

  # PUT /restaurants/:restaurant_id/menus/:id/set_favorite
  def set_favorite
    # Set all menus of the restaurant to not favorite
    @restaurant.menus.update_all(favorite: false)

    # Set the selected menu as favorite
    @menu.update(favorite: true)

    render json: @menu
  end

  # DELETE /restaurants/:restaurant_id/menus/:id
  def destroy
    @menu.destroy
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_menu
    @menu = @restaurant.menus.find(params[:id])
  end

  def menu_params
    params.require(:menu).permit(:name, :description)
  end

  def authorize_restaurant_owner
    return if @restaurant.user == current_user

    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end
end

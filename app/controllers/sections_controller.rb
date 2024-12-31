class SectionsController < ApplicationController
  before_action :set_restaurant
  before_action :set_menu
  before_action :set_section, only: %i[show update destroy]
  before_action :authorize
  before_action :authorize_restaurant_owner, only: %i[create update destroy]

  # GET /restaurants/:restaurant_id/menus/:menu_id/sections
  def index
    @sections = @menu.sections
    render json: @sections
  end

  # GET /restaurants/:restaurant_id/menus/:menu_id/sections/:id
  def show
    render json: @section
  end

  # POST /restaurants/:restaurant_id/menus/:menu_id/sections
  def create
    @section = @menu.sections.build(section_params)

    if @section.save
      render json: @section, status: :created
    else
      render json: @section.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /restaurants/:restaurant_id/menus/:menu_id/sections/:id
  def update
    if @section.update(section_params)
      render json: @section
    else
      render json: @section.errors, status: :unprocessable_entity
    end
  end

  # DELETE /restaurants/:restaurant_id/menus/:menu_id/sections/:id
  def destroy
    @section.destroy
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_menu
    @menu = @restaurant.menus.find(params[:menu_id])
  end

  def set_section
    @section = @menu.sections.find(params[:id])
  end

  def section_params
    params.require(:section).permit(:name, :description)
  end

  def authorize_restaurant_owner
    return if @restaurant.user == current_user

    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end
end

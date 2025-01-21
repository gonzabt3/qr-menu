class ProductsController < ApplicationController
  before_action :set_restaurant
  before_action :set_menu
  before_action :set_section, except: %i[index_by_menu]
  before_action :set_product, only: %i[show update destroy]
  before_action :authorize

  # GET /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products
  def index
    @products = @section.products
    render json: @products
  end

  # GET /restaurants/:restaurant_id/menus/:menu_id/products
  def index_by_menu
    @products = @menu.sections.includes(:products).map(&:products).flatten
    render json: @products
  end

  # GET /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products/:id
  def show
    render json: @product
  end

  # POST /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products
  def create
    @product = @section.products.build(product_params)

    if @product.save
      render json: @product, status: :created
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products/:id
  def update
    if @product.update(product_params)
      render json: @product
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # DELETE /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products/:id
  def destroy
    @product.destroy
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_menu
    @menu = @restaurant.menus.find(params[:menu_id])
  end

  def set_section
    @section = @menu.sections.find(params[:section_id])
  end

  def set_product
    @product = @section.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :price)
  end

  def authorize_restaurant_owner
    return if @section.menu.restaurant.user == current_user

    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end
end

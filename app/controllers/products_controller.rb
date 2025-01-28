require 'tinify'
Tinify.key = ENV['TINY_PNG_API_KEY']

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
    if product_params.key?(:image)
      image = product_params[:image]
      product_params_without_image = product_params.except(:image)
      @product = @section.products.build(product_params_without_image)

      byebug
      # Comprimir la imagen usando Tinify y subirla directamente a S3
      source = Tinify.from_file(image.path)
      s3_path = "uploads/#{image.original_filename}"
      source.store(
        service: 's3',
        aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
        region: ENV['AWS_REGION'],
        path: "#{ENV['S3_BUCKET_NAME']}/#{s3_path}",
        headers: { 'Cache-Control' => 'public, max-age=31536000' }
        # acl: "public-read"
      )

      # Lógica adicional si la clave `image` está presente
      Rails.logger.info 'Image key is present in product_params'
    else
      @product = @section.products.build(product_params)
    end

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
    # tddo agregar image to schema
    params.permit(:name, :description, :price, :image)
  end

  def authorize_restaurant_owner
    return if @section.menu.restaurant.user == current_user

    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end
end

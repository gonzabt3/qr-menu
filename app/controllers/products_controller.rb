require 'tinify'
require 'aws-sdk-s3'
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
    product_params_without_image = product_params.except(:image)
    @product = @section.products.build(product_params_without_image)
    if @product.save
      if product_params.key?(:image)
        image = product_params[:image]
        image_extension = File.extname(image.original_filename)
        s3_path = "menus/#{@menu.id}/products/#{@product.id}#{image_extension}"

        image_url = S3.new.upload_image(image, s3_path)
        @product.update(image_url: image_url)
        # Lógica adicional si la clave `image` está presente
        Rails.logger.info 'Image key is present in product_params'
        render json: @product, status: :created

      else
        render json: @product, status: :created
      end
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products/:id
  def update
    product_params_without_image = product_params.except(:image)
    deleteImageOnS3 if product_params[:image].nil? && product_params[:image] != @product.image_url
    if product_params[:image].present? && product_params[:image] != @product.image_url
      deleteImageOnS3 if @product.image_url.present?
      image = product_params[:image]
      image_extension = File.extname(image.original_filename)
      s3_path = "menus/#{@menu.id}/products/#{@product.id}#{image_extension}"
      image_url = S3.new.upload_image(image,
                                      s3_path)
    end
    product_params_without_image[:image_url] = image_url

    if @product.update(product_params_without_image)
      render json: @product
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # DELETE /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products/:id
  def destroy
    deleteImageOnS3 if @product.image_url.present?
    @product.destroy
  end

  def deleteImageOnS3
    client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
    extension = @product.image_url.split('.').last
    s3_path = "menus/#{@menu.id}/products/#{@product.id}.#{extension}"

    client.delete_object({
                           bucket: ENV['S3_BUCKET_NAME'],
                           key: s3_path
                         })
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

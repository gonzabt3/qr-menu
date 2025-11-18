# frozen_string_literal: true

require 'image_processing/vips'
require 'aws-sdk-s3'

class RestaurantsController < ApplicationController
  before_action :set_restaurant, only: %i[show update destroy]
  before_action :authorize
  before_action :authorize_restaurant_owner, only: %i[update destroy]

  # GET /restaurants
  def index
    @restaurants = Restaurant.all
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
    restaurant_params_without_logo = restaurant_params.except(:logo)
    @restaurant = current_user.restaurants.build(restaurant_params_without_logo)

    if @restaurant.save
      if restaurant_params.key?(:logo)
        logo = restaurant_params[:logo]
        logo_url = process_and_upload_logo(logo)
        @restaurant.update(logo_url: logo_url)
      end
      render json: @restaurant, status: :created
    elsif @restaurant.errors[:name].include?('has already been taken')
      render json: { error: 'Restaurant name must be unique' }, status: :unprocessable_entity
    else
      render json: @restaurant.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /restaurants/:id
  def update
    restaurant_params_without_logo = restaurant_params.except(:logo)

    # Handle logo deletion or update
    if restaurant_params[:logo].nil?
      delete_logo_on_s3 if @restaurant.logo_url.present?
      restaurant_params_without_logo[:logo_url] = nil
    elsif restaurant_params[:logo].present? && restaurant_params[:logo] != @restaurant.logo_url
      # Handle new logo upload
      delete_logo_on_s3 if @restaurant.logo_url.present?
      logo = restaurant_params[:logo]
      logo_url = process_and_upload_logo(logo)
      restaurant_params_without_logo[:logo_url] = logo_url
    else
      # Keep the current logo URL if no new logo is provided
      restaurant_params_without_logo[:logo_url] = @restaurant.logo_url
    end

    if @restaurant.update(restaurant_params_without_logo)
      render json: @restaurant
    else
      render json: @restaurant.errors, status: :unprocessable_entity
    end
  end

  # DELETE /restaurants/:id
  def destroy
    delete_logo_on_s3 if @restaurant.logo_url.present?
    @restaurant.destroy
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
  end

  def restaurant_params
    params.require(:restaurant).permit(:name, :address, :phone, :email, :website, :instagram, :description, :logo)
  end

  def authorize_restaurant_owner
    return if @restaurant.user == current_user

    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end

  def delete_logo_on_s3
    client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
    extension = @restaurant.logo_url.split('.').last
    s3_path = "restaurants/#{@restaurant.id}/logo.#{extension}"

    client.delete_object({
                           bucket: ENV['S3_BUCKET_NAME'],
                           key: s3_path
                         })
    Rails.logger.info "Successfully deleted logo from S3: #{s3_path}"
  rescue Aws::S3::Errors::AccessDenied => e
    Rails.logger.warn "AccessDenied when deleting logo from S3: #{e.message}"
    # Continue execution even if deletion fails
  rescue StandardError => e
    Rails.logger.error "Error deleting logo from S3: #{e.message}"
    # Continue execution even if deletion fails
  end

  def process_and_upload_logo(logo)
    # Use ImageProcessing to resize and convert the image
    processed_logo = ImageProcessing::Vips
                     .source(logo.tempfile)
                     .resize_to_limit(800, 800) # Resize the image to be no larger than 800x800
                     .convert('webp') # Convert to WebP
                     .saver(Q: 80)
                     .call

    # Generate the S3 file path
    logo_extension = '.webp' # Due to conversion, the extension will be WebP
    s3_path = "restaurants/#{@restaurant.id}/logo#{logo_extension}"

    # Upload the optimized image to S3
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
    obj = bucket.object(s3_path)
    obj.upload_file(processed_logo.path, acl: 'public-read')

    obj.public_url
  end
end

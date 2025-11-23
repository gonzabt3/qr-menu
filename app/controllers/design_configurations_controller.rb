# frozen_string_literal: true

class DesignConfigurationsController < ApplicationController
  before_action :authorize
  before_action :set_menu
  before_action :authorize_restaurant_owner

  # GET /restaurants/:restaurant_id/menus/:menu_id/design_configuration
  def show
    design_config = @menu.get_design_configuration
    render json: design_config.to_design_hash
  end

  # POST /restaurants/:restaurant_id/menus/:menu_id/design_configuration
  # PUT /restaurants/:restaurant_id/menus/:menu_id/design_configuration
  def update
    design_config = @menu.get_design_configuration
    
    begin
      design_config.update_from_design_hash(design_params)
      render json: design_config.to_design_hash
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: design_config.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_menu
    @restaurant = Restaurant.find(params[:restaurant_id])
    @menu = @restaurant.menus.find(params[:menu_id])
  end

  def authorize_restaurant_owner
    return if @restaurant.user == current_user

    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end

  def design_params
    params.require(:design).permit(
      :primaryColor, :secondaryColor, :backgroundColor, :textColor, 
      :font, :logoUrl, :showWhatsApp, :showInstagram, :showPhone, :showMaps, :showRestaurantLogo
    )
  end
end
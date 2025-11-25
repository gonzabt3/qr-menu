# app/controllers/metrics/product_taps_controller.rb
module Metrics
  class ProductTapsController < ApplicationController
    skip_before_action :authorize, only: [:create, :dashboard]

    # POST /metrics/product-tap
    def create
      product = Product.find_by(id: product_tap_params[:product_id])
      
      unless product
        render json: { error: 'Product not found' }, status: :not_found
        return
      end

      # Extract user_id from current_user if authenticated, otherwise use session_identifier
      tap_params = {
        product_id: product.id,
        user_id: extract_user_id,
        session_identifier: product_tap_params[:session_identifier]
      }

      product_tap = ProductTap.new(tap_params)

      if product_tap.save
        render json: { 
          message: 'Product tap recorded successfully',
          tap: product_tap.as_json(only: [:id, :product_id, :user_id, :session_identifier, :created_at])
        }, status: :created
      else
        render json: { errors: product_tap.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # GET /metrics/product-taps
    def dashboard
      # Aggregate metrics
      metrics = {
        total_taps: ProductTap.count,
        taps_by_product: aggregate_taps_by_product,
        recent_taps: recent_taps_data,
        top_products: top_products_data
      }

      render json: metrics, status: :ok
    end

    private

    def product_tap_params
      params.permit(:product_id, :session_identifier, :user_id)
    end

    def extract_user_id
      # Try to get user_id from authenticated user if available
      return @current_user.id if @current_user.present?
      # Otherwise, check if user_id is provided in params (for authenticated scenarios)
      product_tap_params[:user_id]
    end

    def aggregate_taps_by_product
      ProductTap.group(:product_id)
                .joins(:product)
                .select('product_taps.product_id, products.name as product_name, COUNT(product_taps.id) as count')
                .order('count DESC')
                .map { |tap| { product_id: tap.product_id, product_name: tap.product_name, count: tap.count } }
    end

    def recent_taps_data
      ProductTap.includes(:product, :user)
                .order(created_at: :desc)
                .limit(50)
                .map do |tap|
        {
          id: tap.id,
          product_id: tap.product_id,
          product_name: tap.product.name,
          user_id: tap.user_id,
          session_identifier: tap.session_identifier,
          created_at: tap.created_at
        }
      end
    end

    def top_products_data
      ProductTap.group(:product_id)
                .joins(:product)
                .select('product_taps.product_id, products.name as product_name, COUNT(product_taps.id) as tap_count')
                .order('tap_count DESC')
                .limit(10)
                .map { |tap| { product_id: tap.product_id, product_name: tap.product_name, tap_count: tap.tap_count } }
    end
  end
end

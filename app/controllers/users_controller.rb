# app/controllers/users_controller.rb
require 'mercadopago'

class UsersController < ApplicationController
  before_action :authorize

  def create
    user = User.new(user_params)
    if user.save
      render json: user, status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  def check_first_login
    user = @current_user

    if user.nil?
      # Si el usuario no existe en la base de datos, es la primera vez que entra
      User.create(auth0_id: user_id, email: email)
      render json: { first_login: true }
    else
      # Si el usuario ya existe en la base de datos, no es la primera vez que entra
      render json: user.as_json.merge(first_login: user.first_time)
    end
  end

  def update
    user = User.find_by(auth0_id: params[:id])
    if user.update(user_params)
      user.update({ first_time: false })
      render json: user, status: :ok
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  def subscribe
    user = User.find_by(email: params[:id])

    if user
      sdk = Mercadopago::SDK.new(ENV['MERCADO_PAGO_ACCESS_TOKEN'])
      custom_headers = {
        'x-idempotency-key': user.id
      }
      preapproval_data = {
        card_token_id: params[:token],
        payer_email: params[:payer]['email'],
        back_url: 'https://www.your-site.com',
        preapproval_plan_id: ENV['MERCADO_PAGO_PRE_APPROVAL_PLAN_ID'],
        reason: 'Suscripción a tu servicio',
        external_reference: user.id.to_s
      }

      response = sdk.preapproval.create(preapproval_data)
      if response[:status] == 201
        user.update(subscribed: true, subscription_id: response[:response]['id'],
                    payer_id: response[:response]['payer_id'])
        render json: user, status: :ok
      else
        render json: { error: 'Subscription failed', details: response['response'] }, status: :unprocessable_entity
      end
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  def unsubscribe
    user = User.find_by(email: params[:id])
    if user && user.subscription_id
      sdk = Mercadopago::SDK.new(ENV['MERCADO_PAGO_ACCESS_TOKEN'])
      response = sdk.preapproval.update(user.subscription_id, { status: 'cancelled' })

      if response[:status] == 200
        user.update(subscribed: false, subscription_id: nil, payer_id: nil)
        render json: { message: 'Subscription cancelled successfully' }, status: :ok
      else
        render json: { error: 'Failed to cancel subscription', details: response['response'] },
               status: :unprocessable_entity
      end
    else
      render json: { error: 'User not found or not subscribed' }, status: :not_found
    end
  end

  private

  def user_params
    params.require(:user).permit(:auth0_id, :email, :name, :surname, :picture, :phone, :address, :birthday, :first_time)
  end
end

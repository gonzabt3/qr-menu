# app/controllers/users_controller.rb
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
    user_id = @current_user["sub"].split("|").last
    email = @current_user["https://qr-menu.io/claims/email"]

    user = User.find_by(auth0_id: user_id)

    if user.nil?
      # Si el usuario no existe en la base de datos, es la primera vez que entra
      User.create(auth0_id: user_id, email:email)
      render json: { first_login: true }
    else
      # Si el usuario ya existe en la base de datos, no es la primera vez que entra
      render json: { first_login: user.first_time }
    end
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      render json: user, status: :ok
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:auth0_id, :email, :name, :surname, :picture, :phone, :address, :birthday, :first_time)
  end
end
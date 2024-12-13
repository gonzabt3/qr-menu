# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authorize

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
      render json: { first_login: false }
    end
  end
end
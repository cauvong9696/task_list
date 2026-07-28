class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]

  def new
    redirect_to tasks_path if logged_in?
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      reset_session # guard against session fixation
      session[:user_id] = user.id
      redirect_to tasks_path, notice: "Signed in."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Signed out."
  end
end

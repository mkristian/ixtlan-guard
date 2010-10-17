class ApplicationController < ActionController::Base
  protect_from_forgery

  protected

  def current_user
    session[:user]
  end
end

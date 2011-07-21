class ApplicationController < ActionController::Base
  protect_from_forgery

  protected

  def current_user
    session[:user]
  end

  def current_domain
    @domain ||= (Domain.find_by_name(params[:domain]) if params[:domain])
  end

  def domain_authorization
    if current_domain
      authorization(:domain) do |allowed| 
        allowed.member?(current_domain.name)
      end
    end
  end
end

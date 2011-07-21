require 'generators/ixtlan/user_management_models/user_management_models_generator'

module Ixtlan
  class UserManagementScaffoldGenerator <  UserManagementModelsGenerator #metagenerator

    source_root File.expand_path('../../templates', __FILE__)
    
    hook_for :user_management_controller, :default => :user_management_controller
    hook_for :stylesheets, :in => :rails
    hook_for :gwt, :type => :boolean, :default => false
  end
end


require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'

module Ixtlan
  class UserManagementModelsGenerator < Rails::Generators::ScaffoldControllerGenerator

    source_root File.expand_path('../templates', __FILE__)
    
  end
end


require 'rails/generators/resource_helpers'
require 'generators/ixtlan/scaffold/scaffold_generator.rb'
module Ixtlan
  class PermissionsScaffoldGenerator < ScaffoldGenerator

   source_root File.expand_path('../../templates', __FILE__)
    arguments.clear # clear name argument from NamedBase
      
    def name # set alias so NamedBase uses the model as its name
      "permission"
    end

    def create_controller_files
      template 'simple_controller.rb', File.join('app', 'controllers', class_path, "#{plural_file_name}_controller.rb")
    end

    def add_routes
      actions.keys.reverse.each do |action|
        route %{get "#{file_name}/#{action}"}
      end
    end

    def aliases
      {}
    end

    def actions
      {'index' => [:*], 'show' => []}
    end
    
  end
end

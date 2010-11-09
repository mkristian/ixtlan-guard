require 'rails/generators/resource_helpers'
require 'generators/ixtlan/scaffold/scaffold_generator.rb'
ActiveSupport::Inflector.inflections do |inflect|
 inflect.irregular 'maintenance', 'maintenance'
end
module Ixtlan
  class MaintenanceScaffoldGenerator < ScaffoldGenerator

    source_root File.expand_path('../../templates', __FILE__)

    arguments.clear # clear name argument from NamedBase
      
    def name # set alias so NamedBase uses the model as its name
      "maintenance"
    end

    def create_controller_files
      template 'simple_controller.rb', File.join('app', 'controllers', class_path, "#{plural_file_name}_controller.rb")
    end

    def add_routes
      actions.reverse.each do |action|
        if action == 'index'
          route %{get "#{file_name}/#{action}"}
        else
          route %{put "#{file_name}/#{action}"}
        end
      end
    end

    def aliases
      {}
    end

    def actions
      ['index', 'block', 'resume']
    end
    
  end
end

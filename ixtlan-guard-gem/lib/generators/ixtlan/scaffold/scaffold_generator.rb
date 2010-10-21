require 'rails/generators/resource_helpers'
module Ixtlan
  class ScaffoldGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers

    source_root File.expand_path('../../templates', __FILE__)
    
#    check_class_collision :suffix => "Guard"
    
    def create_guard_files
      template 'guard.rb', File.join('app', 'guards', class_path, "#{plural_file_name}_guard.rb")
    end
    
    def guard_class_name
      controller_class_name
    end

    def aliases
      { :new => :create, :edit => :update }
    end

    def actions
      ['index', 'show', 'create', 'update', 'destroy']
    end
    
  end
end

require 'rails/generators/resource_helpers'
module Guard
  class ScaffoldGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers

    source_root File.expand_path('../templates', __FILE__)
    
#    check_class_collision :suffix => "Guard"
    
    def create_guard_files
      template 'guard.yml', File.join('app', 'guards', class_path, "#{plural_file_name}_guard.yml")
    end
  end
end

module Guard
  class ControllerGenerator < Rails::Generators::NamedBase

    source_root File.expand_path('../../templates', __FILE__)
      
    argument :actions, :type => :array, :default => [], :banner => "action action"
      
#    check_class_collision :suffix => "Guard"
    
    def create_guard_file
      template 'guard.rb', File.join('app', 'guards', class_path, "#{file_name}_guard.rb")
    end

    def guard_class_name
      class_name
    end

    def aliases
    end

  end
end

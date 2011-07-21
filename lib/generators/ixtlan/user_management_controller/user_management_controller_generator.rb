require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'
require 'generators/ixtlan/scaffold/scaffold_generator'

module Ixtlan
  class UserManagementControllerGenerator < ScaffoldGenerator

    source_root File.expand_path('../../templates', __FILE__)

    class_option :orm, :banner => "NAME", :type => :string, :required => true,
                         :desc => "ORM to generate the controller for"
    class_option :gwt, :banner => "PACKAGE_NAME", :type => :string,
                         :desc => "given gwt package name will generate gwt code"

      
    def create_controller_files
        template 'controller.rb', File.join('app/controllers', class_path, "#{controller_file_name}_controller.rb")
    end

    hook_for :template_engine

  end
end


require 'rails/generators/erb'
require 'rails/generators/resource_helpers'

module Erb
  class UserManagementControllerGenerator < ::Erb::Generators::ScaffoldGenerator
  
    source_root File.expand_path('../templates', __FILE__)
    
  end
end

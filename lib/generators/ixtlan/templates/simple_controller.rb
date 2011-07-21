require 'ixtlan/controllers/<%= plural_file_name %>_controller'
class <%= controller_class_name %>Controller < ApplicationController
  include ::Ixtlan::Controllers::<%= controller_class_name %>Controller
end

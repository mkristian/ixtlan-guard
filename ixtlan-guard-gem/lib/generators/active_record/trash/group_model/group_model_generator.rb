require 'rails/generators/active_record/model/model_generator'
require 'generators/active_record/base'
module ActiveRecord
  #module Ixtlan
  class GroupModelGenerator < Ixtlan::Base

     source_paths << '/home/kristian/projects/ixtlan-guard/ixtlan-guard-gem/target/simple/target/rubygems/gems/activerecord-3.0.0/lib/rails/generators/active_record/model/templates'
     source_root File.expand_path('../../templates', __FILE__)
    
    # arguments.clear # clear name argument from NamedBase
    
    # argument :params, :type => :array, :required => true

    def name
      group_params[0]
    end

    def attributes
      @attributes ||= group_params[1,10000]
    end

    hook_for :test_framework, :as => :model do |instance, model|
p instance.send(:group_params)
p model
      instance.invoke model, instance.send(:group_params)
    end

    def create_model_file
      template 'group.rb', File.join('app/models', class_path, "#{file_name}.rb")
    end

  end
#  end
end

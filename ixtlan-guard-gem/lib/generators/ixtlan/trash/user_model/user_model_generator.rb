module Ixtlan
  class UserModelGenerator < Rails::Generators::NamedBase #metagenerator
    arguments.clear # clear name argument from NamedBase
    argument :params, :type => :array, :default => ['user'], :required => false, :banner => "user_model [field:type ..] [group_model [field:type ..] [flavor_model1 [field:type ..] flavor_model2 [field:type ..]]]", :desc => "group default: group with field name:string"
    
    def name # set alias so NamedBase uses the model as its name
      @params[0].sub(/\s+.*/, '').singularize
    end
    
    hook_for :orm, :required => true
    end
end

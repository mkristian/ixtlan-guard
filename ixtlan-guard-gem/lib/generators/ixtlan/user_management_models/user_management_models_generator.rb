module Ixtlan
  class UserManagementModelsGenerator < Rails::Generators::NamedBase #metagenerator
    arguments.clear # clear name argument from NamedBase
    argument :params, :type => :array, :default => ['user'], :required => false, :banner => "user_model [field:type ..] [group_model [field:type ..] [flavor_model1 [field:type ..] flavor_model2 [field:type ..]]]", :desc => "group default: group with field name:string"
    
    def name # set alias so NamedBase uses the model as its name
      @params[0].sub(/\s+.*/, '').singularize
    end
    
    attr_reader :params

    hook_for :orm, :required => true
    
    # hook_for :group_model, :default => true, :boolen => true do |instance, model|
    #   instance.invoke model, instance.params
    # end
    # hook_for :user_model, :default => true, :boolen => true do |instance, model|
    #   instance.invoke model, instance.params
    # end
    # hook_for :flavor1_model, :default => true, :boolen => true do |instance, model|
    #   instance.invoke model, instance.params
    # end
    # hook_for :flavor2_model, :default => true, :boolen => true do |instance, model|
    #   instance.invoke model, instance.params
    # end
  end
end


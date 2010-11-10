require 'rails/generators/active_record/model/model_generator'
module ActiveRecord
  #module Ixtlan
  class UserManagementModelsGenerator < ::ActiveRecord::Generators::ModelGenerator

    source_paths << ActiveRecord::Generators::ModelGenerator.source_root

    source_root File.expand_path('../templates', __FILE__)
    
    arguments.clear # clear name argument from NamedBase
    
    argument :params, :type => :array, :required => true

    remove_hook_for :test_framework

    def name
      @name ||= user_params[0]
    end

    def attributes
      @attributes ||= user_params[1,10000]
    end

    def attributes=(a = nil)
      @attributes = a
    end

    protected
    def user_params
      retrieve_params(@params)
    end

    def group_params
      result = retrieve_params(@params[user_params.size, 10000])
      case result.size
      when 0
        ["group", "name:string"]
      when 1
        result << "name:string"
      else
        result
      end
    end

    def flavor_params(index, count = 0)
      count = user_params.size + retrieve_params(@params[user_params.size, 10000]).size if count == 0
      if(index > 0)
        count += retrieve_params(@params[count, 10000]).size
        if count != @params.size
          flavor_params(index - 1, count)
        end
      else
        retrieve_params(@params[count, 10000])
      end
    end

    def retrieve_params(params)
      done = nil
      params.select do |para|
        if done.nil?
          done = false
          true
        elsif done
          false
        else
          done = (para =~ /[^:]+\:[^:]+/).nil?
          !done
        end
      end
    end

    public
    
    check_class_collision
    
    class_option :migration,  :type => :boolean
    class_option :timestamps, :type => :boolean
    class_option :parent,     :type => :string, :desc => "The parent class for the generated model"

    def user_name
      @user_name ||= user_params[0].singularize
    end

    def group_name
      @group_name ||= group_params[0].singularize
    end

    def group_field_name
      @group_field_name ||= (group_params[1] || "name:").sub(/\:.*/, '')
    end

    def plural_user_name
      @plural_user_name ||= user_name.pluralize
    end

    def plural_group_name
      @plural_group_name ||= group_name.pluralize
    end

    def user_class_name
      @user_class_name ||= user_name.camelize
    end

    def group_class_name
      @group_class_name ||= group_name.camelize
    end

    def association_name
      @association_name ||= [plural_name, plural_group_name, plural_user_name].sort.join("_")
    end

    def group_user_name
      @group_user_name ||= [plural_group_name, plural_user_name].sort.join("_")
    end

    def flavors
      @flavors ||= params_array[2,10000].collect {|c| c[0].to_s }
    end

    def create_migration_file
      return unless options[:migration] && options[:parent].nil?
      
      index = 0
      params_array.each do |params|
        setup(params)
        migration_template "migration.rb", "db/migrate/create_#{table_name}.rb"
        index += 1
        if(index > 2)
          migration_template "flavor_migration.rb", "db/migrate/create_#{association_name}.rb"
        
        end
      end
      migration_template "group_user_migration.rb", "db/migrate/create_#{group_user_name}.rb"  
    end

    def create_model_file
      setup(user_params)
      template 'user_model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      
      setup(group_params)
      template 'group_model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      
      params_array[2,10000].each do |params|
        setup(params)
        template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
        template 'flavor_model.rb', File.join('app/models', class_path, "#{association_name.singularize}.rb")
      end
    end
    
    def create_module_file
      params_array.each do |params|
        assign_names!(params[0])
        unless class_path.empty?
          template 'module.rb', File.join('app/models', "#{class_path.join('/')}.rb") if behavior == :invoke
        end
      end
    end
    
    protected

    def association_class_name(plural_flavor)
      @association_class_name ||= {}
      @association_class_name[plural_flavor] ||= [plural_flavor, plural_group_name, plural_user_name].sort.join("_").singularize.camelize
    end

    def setup(params)      
      @name = params[0]
      assign_names!(params[0])
      self.attributes = params[1, 10000]
      parse_attributes!
      @file_path = nil
      @class_name = nil
      @human_name = nil
      @plural_name = nil
      @i18n_scope = nil
      @table_name = nil
      @singular_table_name = nil
      @plural_table_name = nil
      @plural_file_name = nil
      @route_url = nil
      @association_name = nil
    end

    def params_array
      @array ||= begin
                   result = [user_params, group_params]
                   index = 0
                   while( flavor = flavor_params(index) ) do
                     result << flavor
                     index += 1
                   end
                   result
                 end
    end

    def parent_class_name
      options[:parent] || "ActiveRecord::Base"
    end
    
  end
#  end
end

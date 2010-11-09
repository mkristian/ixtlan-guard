require 'rails/generators/active_record/model/model_generator'
module ActiveRecord
  module Ixtlan
  class Base < ::ActiveRecord::Generators::ModelGenerator

    source_root '/home/kristian/projects/ixtlan-guard/ixtlan-guard-gem/target/simple/target/rubygems/gems/activerecord-3.0.0/lib/rails/generators/active_record/model/templates'
    source_root File.expand_path('../../templates', __FILE__)
    
    arguments.clear # clear name argument from NamedBase
    
    argument :params, :type => :array, :required => true

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

    def create_migration_file
      return unless options[:migration] && options[:parent].nil?
      migration_template "migration.rb", "db/migrate/create_#{table_name}.rb"
    end

    # def create_model_file
    #   self.attributes = user_params[1, 10000]
    #   parse_attributes!
    #   template 'user.rb', File.join('app/models', class_path, "#{file_name}.rb")
    #   template 'guarded.rb', File.join('app/models', class_path, "guarded_#{file_name}.rb")

    #   attributes = group_params[1, 10000]
    #   parse_attributes!
    #   template 'group.rb', File.join('app/models', class_path, "#{group_name}.rb")
    # end

    def create_module_file
      return if class_path.empty?
      template 'module.rb', File.join('app/models', "#{class_path.join('/')}.rb") if behavior == :invoke
    end
    
    protected
    
    def parent_class_name
      options[:parent] || "ActiveRecord::Base"
    end
    
  end
  end
end

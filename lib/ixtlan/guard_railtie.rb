require 'rails'
require 'ixtlan/guard'
require 'logger'

class GuardRailtie < Rails::Railtie

  config.before_configuration do |app|
    app.config.class.class_eval do
      attr_accessor :guard
    end
    app.config.guard = 
      Ixtlan::Guard.new(Logger.new(STDERR), 
                        :root, 
                        File.join(Rails.root, "app", "guards")) 
  end

  config.after_initialize do |app|
    logger = app.config.logger || Rails.logger || Logger.new(STDERR)
    app.config.guard.logger = logger
    begin
      app.config.guard.setup
    rescue Ixtlan::GuardException => e
      logger.warn e.message
    end
  end

  config.generators do
    require 'rails/generators'
    require 'rails/generators/rails/controller/controller_generator'
    require 'rails/generators/erb/scaffold/scaffold_generator'
    Rails::Generators::ControllerGenerator.hook_for :ixtlan, :type => :boolean, :default => true do |controller|
      invoke controller, [ class_name, actions ]
    end
    Erb::Generators::ScaffoldGenerator.source_paths.insert(0, File.expand_path('../../generators/ixtlan/templates', __FILE__))
    #require 'rails/generators/rails/scaffold/scaffold_generator'
      # somehow the check is before the value is set, 
      # so just ignore the require flag
      #Rails::Generators::ScaffoldGenerator.class_options[:orm].instance_variable_set(:@required, false)
      #Rails::Generators::ScaffoldGenerator.hook_for :ixtlan, :as => :scaffold, :type => :boolean, :default => true do |controller|
      #  invoke controller, [class_name]
      #end
  end
end

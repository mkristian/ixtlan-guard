require 'rails/railtie'
require 'ixtlan/guard/guard'
require 'ixtlan/guard/guard_rails'
require 'logger'
require 'fileutils'

module Ixtlan
  module Guard
    class Railtie < Rails::Railtie

      config.before_configuration do |app|
        app.config.guards_dir = File.join(Rails.root, "app", "guards")
        # needs to be here ?!?
        ::ActionController::Base.send(:include, Ixtlan::Guard::ActionController)
        ::ActionView::Base.send(:include, Ixtlan::Guard::Allowed)
      end
      
      config.after_initialize do |app|
        logger = app.config.logger || Rails.logger || Logger.new(STDERR)
        options = {
          :guards_dir => app.config.guards_dir,
          :cache => app.config.cache_classes
        }
        options[:logger] = logger unless defined?(Slf4r)
        FileUtils.mkdir_p(app.config.guards_dir)

        app.config.guard = Ixtlan::Guard::Guard.new(options)
      end

      gmethod = config.respond_to?(:generators)? :generators : :app_generators
      config.send(gmethod) do
        require 'rails/generators'
        require 'rails/generators/rails/controller/controller_generator'
        Rails::Generators::ControllerGenerator.hook_for :guard, :type => :boolean, :default => true do |controller|
          invoke controller, [ class_name, actions ]
        end
      end
    end
  end
end

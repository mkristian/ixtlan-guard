require 'rails'
require 'ixtlan/guard/guard_ng'
require 'ixtlan/guard/guard_rails'
require 'logger'

module Ixtlan
  module Guard
    class Railtie < Rails::Railtie

      config.before_configuration do |app|
        app.config.guard_dir = File.join(Rails.root, "app", "guards")
      end
      
      config.after_initialize do |app|
        logger = app.config.logger || Rails.logger || Logger.new(STDERR)
        options = {
          :guard_dir => app.config.guard_dir,
          :cache => app.config.cache_classes
        }
        options[:logger] = logger unless defined?(Slf4r)
        app.config.guard = Ixtlan::Guard::GuardNG.new(options)

        ::ActionController::Base.send(:include, Ixtlan::ActionController::Guard)
        ::ActionController::Base.send(:before_filter, :authorization)
        ::ActionView::Base.send(:include, Ixtlan::Allowed)
      end
      
      config.generators do
        require 'rails/generators'
        require 'rails/generators/rails/controller/controller_generator'
        Rails::Generators::ControllerGenerator.hook_for :guard, :type => :boolean, :default => true do |controller|
          invoke controller, [ class_name, actions ]
        end
      end
    end
  end
end

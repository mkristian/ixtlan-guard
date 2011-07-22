require 'rails'
require 'ixtlan/guard'
require 'logger'

module Ixtlan
  module Guard
    class Railtie < Rails::Railtie

      config.before_configuration do |app|
        app.config.guard = 
          Ixtlan::Guard::Guard.new(:guard_dir => File.join(Rails.root, "app", "guards")) 
      end
      
      config.after_initialize do |app|
        logger = app.config.logger || Rails.logger || Logger.new(STDERR)
        app.config.guard.logger = logger unless defined?(Slf4r)
        begin
          app.config.guard.setup
        rescue Ixtlan::Guard::GuardException => e
          logger.warn e.message
        end
      end
    end
  end
end

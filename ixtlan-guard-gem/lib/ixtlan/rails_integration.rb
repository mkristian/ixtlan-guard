require 'ixtlan/guard'
module Ixtlan
  module ActionController #:nodoc:
    module Guard #:nodoc:
      def self.included(base)
        base.send(:include, InstanceMethods)
      end
      module InstanceMethods #:nodoc:

        protected

        def guard
          Rails.configuration.guard
        end

        def authorization(&block)
          resource_authorization(params[:controller], params[:action], &block)
        end

        def resource_authorization(resource, action, &block)
          unless guard.check(self, resource, action, &block)
            raise ::Ixtlan::PermissionDenied.new("permission denied for '#{resource}##{action}'")
          end
          true
        end

        def allowed?(action, &block)
          guard.check(self, params[:controller], action, &block)
        end
      end
    end
  end

  module Allowed #:nodoc:
    # Inclusion hook to make #allowed available as method
    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods #:nodoc:
      def allowed?(resource, action, &block)
        controller.send(:guard).check(controller, resource, action, &block)
      end
    end
  end
end

ActionController::Base.send(:include, Ixtlan::ActionController::Guard)
ActionController::Base.send(:before_filter, :authorization)
ActionView::Base.send(:include, Ixtlan::Allowed)
module Erector
  class Widget
    include Ixtlan::Allowed
  end
end

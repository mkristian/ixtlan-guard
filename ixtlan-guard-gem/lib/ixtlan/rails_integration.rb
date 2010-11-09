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

        def authorization(flavor = nil, &block)
          if flavor.nil?
            flavor = guard.flavor(self)
            if flavor 
              method = "#{flavor}_authorization".to_sym
              if self.respond_to?(method)
                return send "#{flavor}_authorization".to_sym, &block
              else
                logger.warn "flavor #{flavor} confiugred in guard, but there is not method '#{method}'"
                flavor = nil
              end
            end
          end
          resource_authorization(params[:controller], params[:action], flavor, &block)
        end

        def resource_authorization(resource, action, flavor = nil, &block)
          unless guard.check(self, 
                             resource, 
                             action, 
                             &flavored_block(flavor, &block))
            raise ::Ixtlan::PermissionDenied.new("permission denied for '#{resource}##{action}'")
          end
          true
        end

        def flavored_block(flavor = nil, &block)
          if block
            if flavor
              Proc.new do |group|
                allowed_flavors = guard.flavors[flavor.to_sym].call(self, group)
                block.call(allowed_flavors)
              end
            else
              block
            end
          end
        end

        private :flavored_block

        def allowed?(action, flavor = nil, &block)
          guard.check(self, 
                      params[:controller], 
                      action, 
                      &flavored_block(flavor, &block))
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
      def allowed?(resource, action, flavor_selector = nil, &block)
        controller.send(:guard).check(controller, resource, action, flavor_selector, &block)
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

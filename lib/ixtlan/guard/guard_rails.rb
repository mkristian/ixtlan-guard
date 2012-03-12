module Ixtlan
  module ActionController #:nodoc:
    module Guard #:nodoc:
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, GroupsMethod)
      end

      module GroupsMethod

        protected

        def groups_for_current_user
          if respond_to?(:current_user) && current_user
            current_user.groups
          else
            []
          end
        end
      end

      module RootGroup
        protected

        def groups_for_current_user
          ['root']
        end
      end

      module InstanceMethods #:nodoc:

        protected

        def guard
          Rails.application.config.guard
        end

        def allowed?(action, controller = params[:controller], &block)
          group_method = respond_to?(:current_groups) ? :current_groups : :groups_for_current_user
          guard.check(controller, 
                      action,
                      send(group_method) || [],
                      &block) != nil
        end

        def check(&block)
          unless allowed?(params[:action], &block)
            raise ::Ixtlan::Guard::PermissionDenied.new("permission denied for '#{params[:controller]}##{params[:action]}'")
          end
          true
        end
        alias :authorize :check
      end
    end
  end

  module Allowed #:nodoc:
    # Inclusion hook to make #allowed available as method
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
    
    module InstanceMethods #:nodoc:
      def allowed?(action, resource = nil)
        if resource
          controller.allowed?(action, resource)
        else
          controller.allowed?(action)
        end
      end
    end
  end
end

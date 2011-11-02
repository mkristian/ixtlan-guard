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
            current_user.groups.collect do |group|
              group.name
            end
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

        def check(flavor = nil, &block)
          group_method = respond_to?(:current_user_group_names) ? :current_user_group_names : :groups_for_current_user
          unless guard.allowed?(params[:controller], 
                                params[:action],
                                send(group_method),
                                flavor, 
                                &block)
            if flavor
              raise ::Ixtlan::Guard::PermissionDenied.new("permission denied for '#{params[:controller]}##{params[:action]}##{flavor}'")
            else
              raise ::Ixtlan::Guard::PermissionDenied.new("permission denied for '#{params[:controller]}##{params[:action]}'")
            end
          end
          true
        end

        def authorization
          check
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
      def allowed?(resource, action)
        controller.send(:guard).allowed?(resource, action, controller.send(:groups_for_current_user))
      end
    end
  end
end

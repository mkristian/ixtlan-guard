module Ixtlan
  module Guard
    module ActionController
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, GroupsMethod)
        base.send(:before_filter, :authorize)
      end

      class Filter
        attr_reader :block
        def initialize(method, options, &block)
          @only = options[:only]
          @except = options[:except] || []
          @reference = options[:reference]
          @reference = @reference.to_sym if @reference
          @block = block
          @method = method.to_sym if method
          raise "illegal arguments: either block or method name #{method}" if block && method
        end
        
        def proc(base, reference = nil)
          if @block
            if reference
              Proc.new do |groups|
                @block.call(groups, reference)
              end
            elsif @reference
              Proc.new do |groups|
                 @block.call(groups, base.send(@reference))
              end
            else
              @block
            end
          else
            if base.respond_to?(@method) || base.private_methods.include?(@method.to_s) || base.private_methods.include?(@method.to_sym)
              if reference
                Proc.new do |groups|
                  base.send(@method, groups, reference)
                end
              elsif @reference
                Proc.new do |groups|
                  base.send(@method, groups, base.send(@reference))
                end
              else
                base.method(@method)
              end
            else
              if @reference
                Proc.new do |groups|
                  base.class.send(@method, groups, base.send(@reference))
                end
              else
                base.class.method(@method)
              end
            end
          end
        end

        def allowed?(action)
          action = action.to_sym
          (@only && @only.member?(action)) ||
            ((@only.nil? || @only.empty?) && ! @except.member?(action))
        end
      end

      module GroupsMethod

        protected

        def current_groups
          @current_groups ||= 
            if respond_to?(:current_user) && current_user
              current_user.groups
            else
              []
            end
        end
      end

      module RootGroup
        protected

        def current_groups
          ['root']
        end
      end

      module InstanceMethods #:nodoc:

        def self.included(base)
          base.class_eval do

            def self.guard_filter(*args, &block)
              method = nil#"_intern_#{guard_filters.size}"
              options = {}
              case args.size
              when 1
                if args[0].is_a? Symbol
                  method = args[0]
                else
                  options = args[0]
                end
              when 2
                method = args[0].to_sym
                options = args[1]
              else
                raise "argument error, expected (Symbol, Hash) or (Symbol) or (Hash)"
              end
              
              guard_filters << Filter.new(method, options, &block)
            end

            def self.guard_filters
              @_guard_filters ||= []
            end

            def self.guard
              ::Rails.application.config.guard
            end

            def self.allowed?(action, current_groups, reference = nil)
              filter = guard_filters.detect do |f|
                f.allowed?(action)
              end
              if filter
                guard.check(self.controller_name, 
                            action,
                            current_groups || []) do |groups|
                  filter.proc(self, reference).call(groups)
                end
              else
                # TODO maybe do something with the reference
                guard.check(controller_name, 
                            action,
                            current_groups || [])
              end
            end
          end
        end

        protected

        def guard
          self.class.guard
        end

        def allowed?(action_or_actions, 
                     controller = params[:controller], 
                     reference = nil,
                     &block)
          case action_or_actions
          when Array
            action_or_actions.detect do |action|
              check(action, controller, reference, &block) != nil
            end
          else
            check(action_or_actions, controller, reference, &block) != nil
          end
        end

        def check(action = params[:action], 
                  controller = params[:controller],
                  reference = nil,
                  &block)
          unless block
            filter = self.class.guard_filters.detect do |f|
              f.allowed?(action)
            end
          end

          if filter
            guard.check(controller, 
                        action,
                        current_groups || []) do |groups|
              filter.proc(self).call(groups)
            end
          else
            # TODO maybe do something with the reference
            guard.check(controller, 
                        action,
                        current_groups || [],
                        &block)
          end
        end

        def authorize
          unless check
            raise ::Ixtlan::Guard::PermissionDenied.new("permission denied for '#{params[:controller]}##{params[:action]}'")
          end
          true
        end
      end
    end

    module Allowed
      # Inclusion hook to make #allowed available as method
      def self.included(base)
        base.send(:include, InstanceMethods)
      end
    
      module InstanceMethods #:nodoc:
        def allowed?(resource, action, reference = nil)
          if resource.to_s != controller.class.controller_name || reference
            other = "#{resource}Controller".classify.constantize
            if other.respond_to?(:allowed?)
              if reference
                other.send(:allowed?, action, controller.current_groups, reference)
              else
                other.send(:allowed?, action, controller.current_groups)
              end
            else
              raise "can not find 'allowed?' on #{other}"
            end
          else
            controller.send(:allowed?, action, resource)
          end
        end
      end
    end
  end
end

module Ixtlan
  module Guard
    class ControllerGuard
      
      attr_accessor :name, :action_map, :aliases, :flavor

      def initialize(name)
        @name = name.sub(/_guard$/, '').to_sym
        class_name = name.split(/\//).collect { |part| part.split("_").each { |pp| pp.capitalize! }.join }.join("::")
        Object.const_get(class_name).new(self)
      end

      def flavor=(flavor)
        @flavor = flavor.to_sym
      end

      def name=(name)
        @name = name.to_sym
      end

      def aliases=(map)
        @aliases = symbolize(map)
      end

      def action_map=(map)
        @action_map = symbolize(map)
      end

      private

      def symbolize(h)
        result = {}
        
        h.each do |k, v|
          if v.is_a?(Hash)
            result[k.to_sym] = symbolize_keys(v) unless v.size == 0
          elsif v.is_a?(Array)
            val = []
            v.each {|vv| val << vv.to_sym }
            result[k.to_sym] = val
          else
            result[k.to_sym] = v.to_sym
          end
        end
        
        result
      end

    end

    class Guard 

      attr_accessor :logger, :guard_dir, :superuser, :groups_of_current_user

      def initialize(options, &block)
        @superuser = (options[:superuser] || :root).to_sym
        @guard_dir = options[:guard_dir] || File.join("app", "guards")
        @user_groups = (options[:user_groups] || :groups).to_sym
        @user_groups_name = (options[:user_groups_name] || :name).to_sym
        
        @map = {}
        @aliases = {}
        @flavor_map = {}

        @groups_of_current_user =
          if block
            block
          else
            Proc.new do |controller|
              # get the groups of the current_user
              user = controller.send(:current_user) if controller.respond_to?(:current_user)
              if user
                (user.send(@user_groups) || []).collect do |group|
                  name = group.send(@user_groups_name)
                  name.to_sym if name
                end
              end
            end
          end
      end

      def logger
        @logger ||= if defined?(Slf4r::LoggerFactory)
                      Slf4r::LoggerFactory.new(Ixtlan::Guard)
                    else
                      require 'logger'
                      Logger.new(STDOUT)
                    end
      end

      def setup
        if File.exists?(@guard_dir)
          Dir.new(guard_dir).to_a.each do |f|
            if f.match(".rb$")
              require(File.join(guard_dir, f))
              controller_guard = ControllerGuard.new(f.sub(/.rb$/, ''))
              register(controller_guard)
            end
          end
          logger.debug("initialized guard . . .")
        else
          raise GuardException.new("guard directory #{guard_dir} not found, skip loading")
        end
      end

      private

      def register(controller_guard)
        msg = (controller_guard.aliases || {}).collect {|k,v| "\n\t#{k} == #{v}"} + controller_guard.action_map.collect{ |k,v| "\n\t#{k} => [#{v.join(',')}]"}
        logger.debug("#{controller_guard.name} guard: #{msg}")
        @map[controller_guard.name] = controller_guard.action_map
        @aliases[controller_guard.name] = controller_guard.aliases || {}
        @flavor_map[controller_guard.name] = controller_guard.flavor if controller_guard.flavor
      end

      public

      def flavor(controller)
        @flavor_map[controller.params[:controller].to_sym]
      end

      def block_groups(groups)
        @blocked_groups = (groups || []).collect { |g| g.to_sym}
        @blocked_groups.delete(@superuser)
        @blocked_groups
      end

      def blocked_groups
        @blocked_groups ||= []
      end

      def current_user_restricted?(controller)
        groups =  @groups_of_current_user.call(controller)
        if groups
          #        groups.select { |g| !blocked_groups.member?(g.to_sym) }.size < groups.size
          (groups - blocked_groups).size < groups.size
        else
          nil
        end
      end
      
      def permissions(controller)
        groups = (@groups_of_current_user.call(controller) || []).collect do
          |g| g.to_sym
        end
        map = {}
        @map.each do |resource, action_map|
          action_map.each do |action, allowed|
            if allowed.member? :*
              allowed = groups.dup
            end
            allowed << @superuser unless allowed.member? @superuser
            
            # intersection of allowed and groups empty ?
            if (allowed - groups).size < allowed.size
              permission = (map[resource] ||= {})
              permission[:resource] = resource
              actions = (permission[:actions] ||= [])
              action_node = {:name => action}
              flavors.each do |flavor, block|
                flavor_list = []
                (allowed - (allowed - groups)).each do |group|
                  list = block.call(controller, group) 
                  # union - no duplicates
                  flavor_list = flavor_list - list + list
                end
                action_node[flavor.to_s.sub(/s$/, '') + "s"] = flavor_list if flavor_list.size > 0
              end
              actions << { :action => action_node }
              actions << @aliases[resource][action] if @aliases[resource][action]
            end
          end
        end

        result = map.values.collect do |perm|
          { :permission => perm }
        end
        result.class_eval "alias :to_x :to_xml" unless map.respond_to? :to_x
        def result.to_xml(options = {}, &block)
          options[:root] = :permissions unless options[:root]
          to_x(options, &block)
        end

        def result.to_json(options = {}, &block)
          {:permissions => self}.to_json(options, &block)
        end
        result
      end

      def flavors
        @flavors ||= {}
      end

      def register_flavor(flavor, &block)
        flavors[flavor.to_sym] = block
      end

      def check(controller, resource, action, flavor_selector = nil, &block)
        resource = resource.to_sym
        action = action.to_sym
        groups =  @groups_of_current_user.call(controller)
        if groups.nil?
          logger.debug("check #{resource}##{action}: not authenticated")
          return false 
        end
        if (@map.key? resource)
          action = @aliases[resource][action] || action
          allowed = @map[resource][action]
          if (allowed.nil?)
            logger.warn("unknown action '#{action}' for controller '#{resource}'")
            raise ::Ixtlan::Guard::GuardException.new("unknown action '#{action}' for controller '#{resource}'")
          else
            allowed << @superuser unless allowed.member? @superuser
            allow_all_groups = allowed.member?(:*) 
            if(allow_all_groups && block.nil?)
              logger.debug("check #{resource}##{action}: allowed for all")
              return true
            else
              groups.each do |group|
                if (allow_all_groups || allowed.member?(group.to_sym)) && !blocked_groups.member?(group.to_sym)
                  flavor_for_resource = flavors[@flavor_map[resource]]
                  if block.nil?
                    if(flavor_for_resource && flavor_for_resource.call(controller, group).member?(flavor_selector.to_s) || flavor_for_resource.nil?)
                      logger.debug("check #{resource}##{action}: true")
                      return true
                    end
                  elsif block.call(group)
                    logger.debug("check #{resource}##{action}: true")
                    return true
                  end
                end
              end
            end
            logger.debug("check #{resource}##{action}: false")
            return false
          end
        else
          logger.warn("unknown controller for '#{resource}'")
          raise ::Ixtlan::Guard::GuardException.new("unknown controller for '#{resource}'")
        end
      end
    end

    class GuardException < Exception; end
    class PermissionDenied < GuardException; end
  end
end

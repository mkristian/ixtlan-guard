require 'logger'
module Ixtlan
  class ControllerGuard
    
    attr_accessor :name, :action_map, :aliases

    def initialize(name)
      @name = name.sub(/_guard$/, '').to_sym
      class_name = name.split(/\//).collect { |part| part.split("_").each { |pp| pp.capitalize! }.join }.join("::")
      Object.const_get(class_name).new(self)
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

    attr_accessor :logger, :guard_dir, :superuser, :block

    def initialize(logger = Logger.new(STDOUT), superuser = :root, guard_dir = File.join("app", "guards"), &block)
      @map = {}
      @aliases = {}

      @block =
        if block
          block
        else
          Proc.new do |controller|
            # get the groups of the current_user
            user = controller.send(:current_user) if controller.respond_to? :current_user
            user.groups if user
          end
        end
      @logger = logger
      @superuser = superuser
      @guard_dir = guard_dir
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
      msg = controller_guard.action_map.collect{ |k,v| "\n\t#{k} => [#{v.join(',')}]"}
      @logger.debug("#{controller_guard.name} guard: #{msg}")
      @map[controller_guard.name] = controller_guard.action_map
      @aliases[controller_guard.name] = controller_guard.aliases || {}
    end

    public

    def block_groups(groups)
      @blocked_groups = (groups || []).collect { |g| g.to_sym}
      @blocked_groups.delete(@superuser)
      @blocked_groups
    end

    def blocked_groups
      @blocked_groups ||= []
    end

    def current_user_restricted?(controller)
      groups =  @block.call(controller)
      if groups
        groups.select { |g| !blocked_groups.member?(g.to_sym) }.size < groups.size
      else
        nil
      end
    end

     def check(controller, resource, action, &block)
      groups =  @block.call(controller)
      if groups.nil?
        @logger.debug("check #{resource}##{action}: not authenticated")
        return true 
      end
      resource = resource.to_sym
      action = action.to_sym
      if (@map.key? resource)
        action = @aliases[resource][action] || action
        allowed = @map[resource][action]
        if (allowed.nil?)
          @logger.warn("unknown action '#{action}' for controller '#{resource}'")
          raise ::Ixtlan::GuardException.new("unknown action '#{action}' for controller '#{resource}'")
        else
          allowed << @superuser unless allowed.member? @superuser
          allow_all_groups = allowed.member?(:*) 
          if(allow_all_groups && block.nil?)
            @logger.debug("check #{resource}##{action}: allowed for all")
            return true
          else
            groups.each do |group|
              if (allow_all_groups || allowed.member?(group.to_sym)) && !blocked_groups.member?(group.to_sym)
                if(block.nil? || block.call(group))
                  @logger.debug("check #{resource}##{action}: true")
                  return true
                end
              end
            end
          end
          @logger.debug("check #{resource}##{action}: false")
          return false
        end
      else
        @logger.warn("unknown controller for '#{resource}'")
        raise ::Ixtlan::GuardException.new("unknown controller for '#{resource}'")
      end
    end
  end

  class GuardException < Exception; end
  class PermissionDenied < GuardException; end
end


require 'ixtlan/guard/guard_config'

module Ixtlan
  module Guard
    class GuardNG

      def initialize(options = {})
        options[:guards_dir] ||= File.expand_path(".")
        @superuser = [(options[:superuser] || "root").to_s]
        @config = Config.new(options)
        @logger = options[:logger]
      end

      def block_groups(groups)
        @blocked_groups = (groups || []).collect { |g| g.to_s}
        @blocked_groups.delete(@superuser)
        @blocked_groups
      end

      def blocked_groups
        @blocked_groups ||= []
      end

      def logger
        @logger ||= 
          if defined?(Slf4r::LoggerFactory)
            Slf4r::LoggerFactory.new(Ixtlan::Guard)
          else
            require 'logger'
            Logger.new(STDOUT)
          end
      end

      def allowed_groups(resource, action, current_groups)
        allowed = @config.allowed_groups(resource, action) - blocked_groups + @superuser
        if allowed.member?('*')
          current_groups - (blocked_groups - @superuser)
        else
          intersect(allowed, current_groups)
        end
      end

      def allowed?(resource, action, current_groups, flavor = nil, &block)
        current_groups = current_groups.collect { |g| g.to_s }
        allowed_groups = self.allowed_groups(resource, action, current_groups)
       logger.debug { "guard #{resource}##{action}: #{allowed_groups.size > 0}" }
        if allowed_groups.size > 0
          if block
            g = allowed_groups.detect do |group|
              block.call(group).member?(flavor)
            end
            logger.debug do
              if g
                "found group #{g} for #{flavor}" 
              else
                "no group found for #{flavor}"
              end
            end
            g != nil
          else
            true
          end
        else
          unless @config.has_guard?(resource)
            raise ::Ixtlan::Guard::GuardException.new("no guard config for '#{resource}'")
          else
            false
          end
        end
      end

      def permissions(current_groups, flavors = {})
        perms = []
        m = @config.map_of_all
        m.each do |resource, actions|
          nodes = []
          perm = Node.new(:permission)
          perm[:resource] = resource
          perm[:actions] = nodes
          defaults = actions.delete('defaults') || []
          defaults = intersect(current_groups, defaults + @superuser) unless defaults.member?('*')
          # no actions
          # deny = false: !defaults.member?('*')
          # deny = true: defaults.member?('*') || current_groups.member?(@superuser[0])
          deny = if actions.size == 0
                   defaults.member?('*') || current_groups.member?(@superuser[0])
                 else
                   # actions
                   # deny = false : defaults == []
                   # deny = true : defaults.member?('*')
                   defaults.size != 0 || defaults.member?('*')
                 end
          perm[:deny] = deny
          actions.each do |action, groups|
            node = Node.new(:action)
            allowed_groups = 
              if groups && groups.member?('*')
                current_groups
              else
                intersect(current_groups, (groups || []) + @superuser)
              end
            if (deny && allowed_groups.size == 0) || (!deny && allowed_groups.size > 0)
              node[:name] = action
#                f = {}
#                flavors.each do |fl, block|
#                  f[fl] = block.call(allowed_groups)
#                end
#                node[:flavors] = f if f.size > 0
              nodes << node
            end
          end
          perms << perm
        end
        perms
      end

      def permission_map(current_groups, flavors = {})
        # TODO fix it - think first !!
        perms = {}
        m = @config.map_of_all
        m.each do |resource, actions|
          nodes = {}
          actions.each do |action, groups|
            if action == 'defaults'
              nodes[action] = {}
            else
              allowed_groups = intersect(current_groups, (groups || []) + @superuser)
              if allowed_groups.size > 0
                f = {}
                flavors.each do |fl, block|
                  flav = block.call(allowed_groups)
                  f[fl] = flav if flav.size > 0
                end
                nodes[action] = f
              else
                nodes[action] = nil # indicates not default action
              end
            end
          end
          perms[resource] = nodes if nodes.size > 0
        end
        perms
      end

      private
      
      def intersect(set1, set2)
        set1 - (set1 - set2)
      end
    end
    class Node < Hash
      
      def initialize(name)
        map = super
        @content = {}
        merge!({ name => @content })
      end

      def []=(k,v)
        @content[k] = v
      end
      def [](k)
        @content[k]
      end
    end
    class GuardException < Exception; end
    class PermissionDenied < GuardException; end
  end
end

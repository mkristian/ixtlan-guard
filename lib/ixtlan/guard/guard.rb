require 'ixtlan/guard/guard_config'
require 'virtus'
module Ixtlan
  module Guard
    class Guard

      attr_reader :superuser

      def initialize(options = {})
        options[:guards_dir] ||= File.expand_path(".")
        @superuser = [(options[:superuser] || "root").to_s]
        @config = Config.new(options)
        @logger = options[:logger]
      end

      def superuser_name
        @superuser[0]
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

      def allowed_groups(resource_name, 
                         action, 
                         current_group_names)
        allowed = @config.allowed_groups(resource_name, action)
        allowed = allowed - blocked_groups + @superuser
        if allowed.member?('*')
          # keep superuser in current_groups if in there
          current_group_names - (blocked_groups - @superuser)
        else
          allowed & current_group_names
        end
      end

      def group_map(current_groups)
        names = current_groups.collect do |g| 
          key = case g
                when String 
                  g
                when Symbol 
                  g.to_s
                else 
                  g.name.to_s
                end
          [key, g] 
        end
        Hash[*(names.flatten)]
      end
      private :group_map

      def check(resource_name, action, current_groups, &block)
        action = action.to_s
        group_map = group_map(current_groups)
        allowed_group_names = allowed_groups(resource_name, action, group_map.keys)

        if allowed_group_names.size > 0
          groups = allowed_group_names.collect { |name| group_map[name] }
          # call block to filter groups unless we are superuser
          if block && !allowed_group_names.member?(superuser_name)
            groups = block.call(groups)
          end
          
          logger.debug { "guard #{resource_name}##{action}: #{groups.size > 0}" }

          # nil means 'access denied', i.e. there are no allowed groups
          groups if groups.size > 0
        else
          unless @config.has_guard?(resource_name)
            raise ::Ixtlan::Guard::GuardException.new("no guard config for '#{resource_name}'")
          else
            logger.debug { "guard #{resource_name}##{action}: #{allowed_group_names.size > 0}" }
            # nil means 'access denied', i.e. there are no allowed groups
            nil
          end
        end
      end

      def allowed?(resource, action, groups, &block)
        check(resource, action, groups, &block) != nil
      end

      def permissions(current_groups, &block)
        group_map = group_map(current_groups)
        perms = []
        m = @config.map_of_all
        m.each do |resource, actions|
          nodes = []
          perm = Permission.new #Node.new(:permission)
          perm.resource = resource
          perm.actions = []#nodes

          # setup default_groups
          default_groups = actions.delete('defaults') || []
          default_groups = group_map.keys & (default_groups + @superuser) unless default_groups.member?('*')

          deny = if actions.size == 0
                   # no actions
                   # deny = false: !default_groups.member?('*')
                   # deny = true: default_groups.member?('*') || current_group_names.member?(@superuser[0])
                   default_groups.member?('*') || group_map.keys.member?(@superuser[0]) || !group_map.keys.detect {|g| default_groups.member? g }.nil?
                 else
                   # actions
                   # deny = false : default_groups == []
                   # deny = true : default_groups.member?('*')
                   default_groups.size != 0 || default_groups.member?('*')
                 end
          perm.deny = deny

          actions.each do |action, groups|
            group_names = groups.collect { |g| g.is_a?(Hash) ? g.keys : g }.flatten if groups
            node = Action.new #Node.new(:action)
            allowed_groups = 
              if groups && group_names.member?('*')
                group_map.values
              else
                names = group_map.keys & ((group_names || []) + @superuser)
                names.collect { |name| group_map[name] }
              end
            if (deny && allowed_groups.size == 0) || (!deny && allowed_groups.size > 0)
              node.name = action
              if block
                if allowed_groups.size > 0
                  assos = block.call(resource, allowed_groups)
                  node.associations = assos if assos && assos.size > 0
                else
                  assos = block.call(resource, group_map.values)
                  perm.associations = assos if assos && assos.size > 0
                end
              end
              perm.actions << node
            elsif deny && allowed_groups.size > 0 && block
              assos = block.call(resource, group_map.values)
              perm.associations = assos if assos && assos.size > 0
            end
          end
          # TODO is that right like this ?
          # only default_groups, i.e. no actions !!!
          if block && actions.size == 0 && deny
            assos = block.call(resource, group_map.values)
            perm.associations = assos if assos && assos.size > 0
          end
          perms << perm
        end
        perms
      end
    end
    class Action   
      include Virtus

      attribute :name, String
      attribute :associations, Array[String]
    end
    class Permission   
      include Virtus

      attribute :resource, String
      attribute :actions, Array[Action]
      attribute :deny, Boolean
      attribute :associations, Array[String]
    end
    class GuardException < Exception; end
    class PermissionDenied < GuardException; end
  end
end

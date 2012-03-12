require 'ixtlan/guard/guard_config'

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

      def allowed_groups_and_restricted(resource_name, 
                                        action, 
                                        current_group_names)
        allowed, restricted = 
          @config.allowed_groups_and_restricted(resource_name, action)
        allowed = allowed - blocked_groups + @superuser
        result = if allowed.member?('*')
                   # keep superuser in current_groups if in there
                   current_group_names - (blocked_groups - @superuser)
                 else
                   allowed & current_group_names
                 end
        [result, restricted]
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
        allowed_group_names, restricted = 
          allowed_groups_and_restricted(resource_name, action, group_map.keys)
        
        logger.debug { "guard #{resource_name}##{action}: #{allowed_group_names.size > 0}" }

        if allowed_group_names.size > 0
          groups = allowed_group_names.collect { |name| group_map[name] }
          # call block to filter groups if restricted applies
          if restricted && !allowed_group_names.member?(superuser_name)
            raise "no block given to filter groups" unless block 
            except = restricted['except'] || []
            only = restricted['only'] || [action]
            if !except.member?(action) && only.member?(action)
              groups = block.call(groups)
            end
          end

          # nil means 'access denied', i.e. there are no allowed groups
          groups if groups.size > 0
        else
          unless @config.has_guard?(resource_name)
            raise ::Ixtlan::Guard::GuardException.new("no guard config for '#{resource_name}'")
          else
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
          perm = Node.new(:permission)
          perm[:resource] = resource
          perm[:actions] = nodes

          restricted = actions.delete('restricted')

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
          perm[:deny] = deny

          actions.each do |action, groups|
            group_names = groups.collect { |g| g.is_a?(Hash) ? g.keys : g }.flatten if groups
            node = Node.new(:action)
            allowed_groups = 
              if groups && group_names.member?('*')
                group_map.values
              else
                names = group_map.keys & ((group_names || []) + @superuser)
                names.collect { |name| group_map[name] }
              end

            if (deny && allowed_groups.size == 0) || (!deny && allowed_groups.size > 0)
              node[:name] = action
              if block
                if allowed_groups.size > 0
                  assos = block.call(resource, allowed_groups)
                  node[:associations] = assos if assos && assos.size > 0
                else
                  assos = block.call(resource, group_map.values)
                  perm[:associations] = assos if assos && assos.size > 0
                end
              end
              nodes << node
            elsif deny && allowed_groups.size > 0 && block
              assos = block.call(resource, group_map.values)
              perm[:associations] = assos if assos && assos.size > 0
            end
          end
          # TODO is that right like this ?
          # only default_groups, i.e. no actions !!!
          if block && actions.size == 0 && deny
            assos = block.call(resource, group_map.values)
            perm[:associations] = assos if assos && assos.size > 0
          end
          perms << perm
        end
        perms
      end
    end
    class Node < Hash

      attr_reader :content

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

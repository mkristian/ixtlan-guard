require 'ixtlan/guard/guard_config'

module Ixtlan
  module Guard
    class GuardNG

      attr_reader :superuser

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

      def allowed_groups(resource_name, action, current_group_names)
        allowed = @config.allowed_groups(resource_name, action) - blocked_groups + @superuser
        if allowed.member?('*')
          # keep superuser in current_groups if in there
          current_group_names - (blocked_groups - @superuser)
        else
          intersect(allowed, current_group_names)
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

      def allowed?(resource_name, action, current_groups, association = nil, &block)
        group_map = group_map(current_groups)
        allowed_group_names = allowed_groups(resource_name, action, group_map.keys)
        logger.debug { "guard #{resource_name}##{action}: #{allowed_group_names.size > 0}" }
        if allowed_group_names.size > 0
          if block || association
            group_allowed?(group_map, allowed_group_names, association, &block)
          else
            true
          end
        else
          unless @config.has_guard?(resource_name)
            raise ::Ixtlan::Guard::GuardException.new("no guard config for '#{resource_name}'")
          else
            false
          end
        end
      end

      def group_allowed?(group_map, allowed_group_names, association, &block)
        g = allowed_group_names.detect do |group_name|
          block.call(group_map[group_name], association)
        end if association && block
        logger.debug do
          if g
            "found group #{g} for #{association}" 
          else
            "no group found for #{association}"
          end
        end
        g != nil
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
          defaults = actions.delete('defaults') || []
          defaults = intersect(group_map.keys, defaults + @superuser) unless defaults.member?('*')
          deny = if actions.size == 0
                   # no actions
                   # deny = false: !defaults.member?('*')
                   # deny = true: defaults.member?('*') || current_group_names.member?(@superuser[0])
                   defaults.member?('*') || group_map.keys.member?(@superuser[0])
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
                group_map.values
              else
                names = intersect(group_map.keys, (groups || []) + @superuser)
                names.collect { |name| group_map[name] }
              end
            if (deny && allowed_groups.size == 0) || (!deny && allowed_groups.size > 0)
              node[:name] = action
              if block 
                if allowed_groups.size > 0
                  node.content.merge!(block.call(allowed_groups))
                else
                  perm.content.merge!(block.call(group_map.values))
                end
              end
              nodes << node
            end
          end
          if block && actions.size == 0 && deny
            perm.content.merge!(block.call(group_map.values))
          end
          perms << perm
        end
        perms
      end

      # def permission_map(current_groups, associations = {})
      #   # TODO fix it - think first !!
      #   perms = {}
      #   m = @config.map_of_all
      #   m.each do |resource, actions|
      #     nodes = {}
      #     actions.each do |action, groups|
      #       if action == 'defaults'
      #         nodes[action] = {}
      #       else
      #         allowed_groups = intersect(current_groups, (groups || []) + @superuser)
      #         if allowed_groups.size > 0
      #           f = {}
      #           associations.each do |a, block|
      #             asso = block.call(allowed_groups)
      #             f[a] = asso if asso.size > 0
      #           end
      #           nodes[action] = f
      #         else
      #           nodes[action] = nil # indicates not default action
      #         end
      #       end
      #     end
      #     perms[resource] = nodes if nodes.size > 0
      #   end
      #   perms
      # end

      private
      
      def intersect(set1, set2)
        set1 - (set1 - set2)
      end

      def union(set1, set2)
        set1 - set2 + set2
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

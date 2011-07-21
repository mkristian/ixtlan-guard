module Ixtlan
  module Guard
    module Models
      class UserUpdateManager

        def initialize(options)
          @group_model = options[:group_model]
          @user_id = options[:user_id].to_sym
          @plural_group_name = options[:plural_group_name].to_sym
          @group_id = options[:group_id].to_sym
          @group_ids = "#{options[:group_id]}s"
        end
        
        def update_groups(user, params = [])
          allowed_ids = user.current_user.all_groups.collect { |g| g.id.to_s }
          
          group_ids = params[@group_ids] || []
          group_ids = intersect(group_ids, allowed_ids)
          
          current_ids = user.send(@plural_group_name).collect { |g| g.id.to_s }
          current_ids = intersect(current_ids, allowed_ids)
          
          # add
          (group_ids - current_ids).each do |gid|
            user.send(@plural_group_name) << @group_model.find(gid)
          end
          
          #delete
          (current_ids - group_ids).each do |gid|
            user.groups.delete(@group_model.find(gid))
          end
          
          user.save
        end
        
        def update(user, params = {}, options = {})
          raise "no user" unless user
          user.current_user = params.delete("current_user") || params.delete(:current_user) unless user.current_user
          raise "'current_user' not set" unless user.current_user
          
          flavor_id = options[:flavor_id].to_sym
          flavor_ids = "#{options[:flavor_id]}s"
          association_model = options[:association_model]
          retrieve_flavors_method = options[:flavors_for_group].to_sym
          
          allowed_ids = user.current_user.send(retrieve_flavors_method, @group_model.admin_group).collect {|i| i.id }
          allowed_group_ids = user.current_user.all_groups.collect { |g| g.id.to_s }

          group_ids = params[@group_ids] || []
          group_ids = intersect(group_ids, allowed_group_ids)
          group_ids.each do |gid|
            g = @group_model.find(gid)
            
            # calculate intersection of current and allowed
            current_ids = user.send(retrieve_flavors_method, gid.to_i).collect { |d| d.id }
            current_ids = intersect(current_ids, allowed_ids)
            
            # calculate intersection of target and allowed
            target_ids = ((params.delete(g.to_name) || {})[flavor_ids] || []).collect { |i| i.to_i }
            target_ids = intersect(target_ids, allowed_ids)
            
            # delete
            (current_ids - target_ids).each do |id|
              return false unless association_model.delete_all(["user_id=? and group_id=? and #{flavor_id}=?", user.id, gid, id])
            end
            
            # add
            (target_ids - current_ids).each do |id|
              return false unless association_model.create(@user_id => user.id, @group_id => gid, flavor_id => id)
            end
          end
          true
        end
        
        def managed_flavors_for_group(user, group_or_id, options)
          retrieve_flavors_method = options[:flavors_for_group].to_sym
          group = @group_model.get(group_or_id)
          if group.root?
            []
          else
            existing = user.send(retrieve_flavors_method, group)
            managed = user.send(retrieve_flavors_method, @group_model.admin_group)
            intersect(managed, existing)
          end
        end
        
        private
        
        def intersect(set1, set2)
          set1 - (set1 - set2)
        end
      end
    end
  end
end

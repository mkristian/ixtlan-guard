class UpdateManager

  def initialize(options)
    @group_model = options[:group_model]
    @user_id = options[:user_id].to_sym
    @group_id = options[:group_id].to_sym
  end

  def update(user, params = [], options)
    raise "'current_user' not set" unless user && user.current_user
    flavor_id = options[:flavor_id].to_sym
    flavor_ids = "#{options[:flavor_id]}s".to_sym
    association_model = options[:association_model]
    retrieve_flavors_method = options[:flavors_for_group].to_sym
    
    allowed_ids = user.current_user.send(retrieve_flavors_method, @group_model.admin_group)
      
    group_ids = params[:group_ids] || []
    allowed_group_ids = user.current_user.groups.collect { |g| g.id.to_s }
    group_ids = intersection(group_ids, allowed_group_ids)
    params[:group_ids] = group_ids
    group_ids.each do |gid|
      g = @group_model.find(gid)
      flavor_ids = user.send(retrieve_flavors_method, gid.to_i).collect { |d| d.id }
      # calculate intersection of flavors and allowed
      existing_ids = intersection(flavor_ids, allowed_ids)

      target_ids = ((params.delete(g.to_name) || {})[flavor_ids] || []).collect { |i| i.to_i }
      
      # delete 
      (existing_ids - target_ids).each do |id|
        return false unless association_model.delete_all(@user_id => user.id, @group_id => gid, flavor_id => id)
      end
      # add
      ids = target_ids - existing_ids
      intersection(ids, allowed_ids).each do |id|
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
      intersection(managed, existing))
    end
  end

  private

  def intersection(set1, set2)
    set1 - (set1 - set2)
  end
end

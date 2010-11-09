module Guarded<%= class_name %>

  def root?
    <%= plural_group_name %>.detect {|g| g.root? } != nil
  end

<% flavors.each do |flavor| 
   plural_flavor = flavor.pluralize  %>
  def managed_<%= plural_flavor %>_for_<%= group_name %>(gid)
    <%= group_name %> = <%= group_class_name %>.get(gid)
    if <%= group_name %>.root?
      []
    else
      existing = <%= plural_flavor %>_for_<%= group_name %>(<%= group_name %>)
      managed = <%= plural_flavor %>_for_<%= group_name %>(<%= group_class_name %>.admin_group)
      (managed - (managed - existing))
    end
  end

  def <%= plural_flavor %>_for_<%= group_name %>(group_or_id)
    if root?
      <%= flavor.camelize %>.all
    else
      <%= group_name %> = <%= group_class_name %>.get(group_or_id)
      <%= association_class_name(plural_flavor) %>.all(:conditions => ["<%= user_name %>_id=? and <%= group_name %>_id=?", id, <%= group_name %>.id]).collect { |dgu| dgu.<%= flavor %> }
    end
  end

  def <%= flavor %>_<%= group_name %>?(<%= flavor %>, <%= group_name %>)
    <%= association_class_name(plural_flavor) %>.count(:conditions => ["<%= user_name %>_id=? and <%= group_name %>_id=? and <%= flavor %>_id=?", id, <%= group_name %>.id, <%= flavor %>.id]) == 1 
  end

<% end -%>

  def all_<%= plural_group_name %>
    if root?
      <%= group_class_name %>.all
    else
      <%= plural_group_name %>
    end
  end

  def to_name
    <%= group_field_name %>
  end

  def to_xml
    to_hash.to_xml(:root => "<%= file_name %>")
  end

  def to_json
    { :<%= file_name %> => to_hash }.to_json
  end

  def to_hash
    map = attributes.dup
    g = (map[:<%= plural_group_name %>] = [])
    <%= plural_group_name %>.each do |<%= group_name %>|
      gg = <%= group_name %>.attributes.dup
      gg.delete("<%= group_name %>_id")
      gg.delete("<%= file_name %>_id")
<% flavors.each do |flavor| 
   plural_flavor = flavor.pluralize  %>
      <%= plural_flavor %> = <%= plural_flavor %>_for_<%= group_name %>(<%= group_name %>)
      if <%= plural_flavor %>.size > 0
        d = (gg[:<%= plural_flavor %>] = [])
        <%= plural_flavor %>.each do |<%= flavor %>|
          dd = <%= flavor %>.attributes.dup
          dd.delete("created_at")
          dd.delete("updated_at")
          d << dd
        end
      end
<% end -%>
      g << gg
    end
    map
  end
end

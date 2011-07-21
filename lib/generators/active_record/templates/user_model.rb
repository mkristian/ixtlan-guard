require 'ixtlan/guard/models/user_update_manager'
class <%= user_class_name %> < <%= parent_class_name.classify %>
<% attributes.select {|attr| attr.reference? }.each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>

  has_and_belongs_to_many :<%= plural_group_name %>

  attr_accessor :id

  def self.update_manager
    @manager ||= Ixtlan::Guard::Models::UserUpdateManager.new( :group_model => <%= group_class_name %>, :user_id => :<%= user_name %>_id, :group_id => :<%= group_name %>_id, :plural_group_name => :<%= plural_group_name %> )
  end

  alias :create! :create
  def self.create(params = {})
    u = self.new
    u.current_user = params.delete("current_user") || params.delete(:current_user)
    u.update_attributes(params)
    u
  end

  def update_attributes(params)
    result = []
 <% flavors.each do |flavor| %>
    # update <%= flavor.pluralize %>
    if result.all?{|a| a} 
      result << self.class.update_manager.update(self, params, :flavor_id => :<%= flavor %>_id, :flavors_for_group => :<%= flavor.pluralize %>_for_<%= group_name %>, :association_model => <%= association_class_name(flavor.pluralize) %>) 
    end
<% end -%> 

    # update <%= plural_group_name %>
    self.class.update_manager.update_groups(self, params) if result.all?{|a| a}
  end

  unless respond_to? :current_user
    # do not use attr_accessor to allow them to be used 
    # for mass_assignmnet_protection
    def current_user=(u)
      @current_user = u
    end
    
    def current_user
      @current_user
    end

    after_save do
      @current_user = nil
    end
  end

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

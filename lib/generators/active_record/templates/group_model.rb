class <%= group_class_name %> < <%= parent_class_name.classify %>
<% attributes.select {|attr| attr.reference? }.each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>

  has_and_belongs_to_many :<%= plural_user_name %>

  ROOT = 'root'
  ADMIN = 'admin'

  def self.admin_group
    find_by_<%= attributes.first.name %>(ADMIN)
  end

  def self.root_group
    find_by_<%= attributes.first.name %>(ROOT)
  end

  def admin?
    <%= attributes.first.name %> == ADMIN
  end

  def root?
    <%= attributes.first.name %> == ROOT
  end

  def self.get(id_or_<%= attributes.first.name %>_or_<%= file_name %>)
    case id_or_<%= attributes.first.name %>_or_<%= file_name %>
    when Fixnum
      find(id_or_<%= attributes.first.name %>_or_<%= file_name %>)
    when String
      find_by_<%= attributes.first.name %>(id_or_<%= attributes.first.name %>_or_<%= file_name %>)
    when Symbol
      find_by_<%= attributes.first.name %>(id_or_<%= attributes.first.name %>_or_<%= file_name %>.to_s)
    else
      id_or_<%= attributes.first.name %>_or_<%= file_name %>
    end
  end

  def to_name
    <%= group_field_name %>
  end
end

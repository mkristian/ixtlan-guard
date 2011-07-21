class <%= association_class_name(plural_name) %> < <%= parent_class_name.classify %>
<% attributes.select {|attr| attr.reference? }.each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
<% [name, group_name, user_name].sort.each do |ref_name| -%>
  belongs_to :<%= ref_name %>
<% end -%>
end

class <%= guard_class_name %>Guard
  def initialize(guard)
    #guard.name = "<%= plural_file_name %>"
<% if aliases -%>
    guard.aliases = <%= aliases.inspect %>
<% end -%>
    guard.action_map= {
<% for action in actions -%>
      :<%= action %> => [],
<% end -%>
    }
  end
end

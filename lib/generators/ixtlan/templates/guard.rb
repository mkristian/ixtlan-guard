class <%= guard_class_name %>Guard
  def initialize(guard)
    #guard.name = "<%= plural_file_name %>"
<% if aliases -%>
    guard.aliases = <%= aliases.inspect %>
<% end -%>
    guard.action_map= {
<% case actions
   when Array
     for action in actions -%>
       :<%= action %> => [],
<%   end 
   when Hash
     actions.each do |action, groups| -%>
      :<%= action %> => <%= groups.inspect %>,
<%   end
   end -%>
    }
  end
end

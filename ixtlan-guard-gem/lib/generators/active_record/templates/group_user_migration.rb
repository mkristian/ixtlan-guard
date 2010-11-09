class Create<%= group_user_name.camelize %> < ActiveRecord::Migration
  def self.up
    create_table :<%= group_user_name %>, :id => false, :force => true do |t|
      <% [group_name, user_name].sort.each do |name| -%>
      t.integer :<%= name %>_id
      <% end -%>
    end
  end

  def self.down
    drop_table :<%= group_user_name %>
  end
end

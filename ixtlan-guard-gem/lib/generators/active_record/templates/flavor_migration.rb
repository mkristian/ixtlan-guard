class Create<%= association_name.camelize %> < ActiveRecord::Migration
  def self.up
    create_table :<%= association_name %>, :id => false, :force => true do |t|
      <% [file_name, group_name, user_name].sort.each do |name| -%>
      t.integer :<%= name %>_id
      <% end -%>
    end
  end

  def self.down
    drop_table :<%= association_name %>
  end
end

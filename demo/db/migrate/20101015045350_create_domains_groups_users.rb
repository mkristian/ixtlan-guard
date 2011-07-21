class CreateDomainsGroupsUsers < ActiveRecord::Migration
  def self.up
    create_table :domains_groups_users, :id => false, :force => true do |t|
      t.integer :domain_id
      t.integer :group_id
      t.integer :user_id
    end
  end

  def self.down
    drop_table :domains_groups_users
  end
end

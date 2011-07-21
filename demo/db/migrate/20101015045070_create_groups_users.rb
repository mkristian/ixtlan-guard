class CreateGroupsUsers < ActiveRecord::Migration
  def self.up
    create_table :groups_users, :id => false, :force => true do |t|
      t.integer :group_id
      t.integer :user_id
    end
  end
 
  def self.down
    drop_table :groups_users
  end
  
end

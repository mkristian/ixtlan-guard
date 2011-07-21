class Group < ActiveRecord::Base
  has_and_belongs_to_many :users

  ROOT = 'root'
  ADMIN = 'admin'

  def self.admin
    find_by_name(ADMIN)
  end

  def self.root
    find_by_name(ROOT)
  end

  def admin?
    name == ADMIN
  end

  def root?
    name == ROOT
  end
end

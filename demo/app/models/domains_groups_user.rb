class DomainsGroupsUser < ActiveRecord::Base
  belongs_to :domain
  belongs_to :group
  belongs_to :user
end

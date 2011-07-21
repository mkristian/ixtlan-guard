class User < ActiveRecord::Base

  has_and_belongs_to_many :groups

  include GuardUser

  attr_accessor :current_user
end

#   def root?
#     groups.detect {|g| g.root? } != nil
#   end

#   def managed_domains_for_group(gid)
#     group = case(gid)
#             when Fixnum
#               Group.find(gid)
#             when String
#               Group.find_by_name(gid)
#             when Symbol
#               Group.find_by_name(gid.to_s)
#             else
#               gid
#             end
#     if group.root?
#       []
#     else
#       existing = domains_for_group(group)
#       managed = domains_for_group(Group.admin)
#       (managed - (managed - existing))
#     end
#   end

#   def domains_for_group(gid)
#     if root?
#       Domain.all
#     else
#       group = case(gid)
#             when Fixnum
#               gid
#             when String
#               Group.find_by_name(gid).id
#             when Symbol
#               Group.find_by_name(gid.to_s).id
#             else
#               gid.id
#             end
#       DomainsGroupsUser.all(:conditions => ["user_id=? and group_id=?", id, group]).collect { |dgu| dgu.domain }
#     end
#   end

#   def domain_group?(domain, group)
#     DomainsGroupsUser.all(:conditions => ["user_id=? and group_id=? and domain_id=?", id, group.id, domain.id]).size == 1 
#   end

#   def all_groups
#     if root?
#       Group.all
#     else
#       groups
#     end
#   end

#   def to_xml
#     to_hash.to_xml(:root => "user")
#   end

#   def to_json
#     { :user => to_hash }.to_json
#   end

#   def to_hash
#     map = attributes.dup
#     g = (map[:groups] = [])
#     groups.each do |group|
#       gg = group.attributes.dup
#       gg.delete("group_id")
#       gg.delete("user_id")
#       domains = domains_for_group(group)
#       if domains.size > 0
#         d = (gg[:domains] = [])
#         domains.each do |domain|
#           dd = domain.attributes.dup
#           dd.delete("created_at")
#           dd.delete("updated_at")
#           d << dd
#         end
#       end
#       g << gg
#     end
#     map
#   end
# end

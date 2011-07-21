# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

root = Group.create(:id =>1, :name => "root")
users = Group.create(:id =>2, :name => "users")
courses = Group.create(:id =>3, :name => "courses")
_teachers = Group.create(:id =>4, :name => "teachers")
_translators = Group.create(:id =>5, :name => "translators")
locales = Group.create(:id =>6, :name => "locales")

u = User.create({:name => "root"})
u.groups << root
u.save
admins = []
registrars = []
teachers = []
translators = []
(1..3).each do |i|
  u = User.create({:name => "admin#{i}"})
  u.groups << users
  u.groups << courses
  u.save
  admins << u
  u = User.create({:name => "registrar#{i}"})
  u.groups << courses
  u.save
  registrars << u
  u = User.create({:name => "teacher#{i}"})
  u.groups << _teachers
  u.save
  teachers << u
  if i < 3
     u = User.create({:name => "translator#{i}"})
    u.groups << _translators
    u.save
    translators << u
  end
end
u = User.find_by_name("admin3")
u.groups << _translators
u.groups << locales
u.save

Domain.create(:id => 1, :name => "europe")
Domain.create(:id => 2, :name => "asia")

[admins, registrars, teachers].each do |users|
  (1..2).each do |did|
    DomainsGroupsUser.create(:domain_id => did, :group_id => users[did - 1].groups.first.id, :user_id => users[did - 1].id)
    DomainsGroupsUser.create(:domain_id => did, :group_id => users[2].groups.first.id, :user_id => users[2].id)
  end
end
(1..2).each do |did|
  DomainsGroupsUser.create(:domain_id => did, :group_id => courses.id, :user_id => admins[did - 1].id)
end
Course.create(:domain_id => 2, :kind => "10-day")
Course.create(:domain_id => 1, :kind => "3-day")
Course.create(:domain_id => 2, :kind => "children")

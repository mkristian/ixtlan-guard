# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

User.create({:id => 1, :name => "root"})
User.create({:id => 2, :name => "admin"})
User.create({:id => 3, :name => "registrar"})
User.create({:id => 4, :name => "teacher"})

Domain.create(:id => 1, :name => "europe")
Domain.create(:id => 2, :name => "asia")

Course.create(:domain_id => 2, :kind => "10-day")
Course.create(:domain_id => 1, :kind => "3-day")
Course.create(:domain_id => 2, :kind => "children")

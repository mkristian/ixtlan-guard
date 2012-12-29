require 'spec_helper'
require 'ixtlan/guard/guard'
require 'logger'

class Group

  attr_accessor :name, :domains

  def initialize(name, *domains)
    @name = name
    @domains = domains.flatten
  end
end

describe Ixtlan::Guard::Guard do

  subject do
    logger = Logger.new(STDOUT)
    def logger.debug(&block)
     # info("\n\t[debug] " + block.call)
    end
    Ixtlan::Guard::Guard.new(:guards_dir => File.join(File.dirname(__FILE__), "guards"), :logger => logger )
  end

  it 'should pass without block' do
    subject.allowed?(:users, :edit, [Group.new(:users)]).should be_true
  end

  it 'should deny with block returning empty array' do
    subject.allowed?(:users, :update, [Group.new(:users)]){ |groups| [] }.should be_false
  end

  it 'should allow root user' do
    subject.allowed?(:users, :update, [Group.new(:root)]){ |groups| [] }.should be_true
  end

  it 'should pass with matching association' do
    subject.allowed?(:users, :update, [Group.new(:users, :manager)]) do |groups|
      groups.select { |g| g.domains.member? :manager }
    end.should be_true
  end

  it 'should fail with mismatching association' do
    subject.allowed?(:users, :update, [Group.new(:users, :manager)]) do |groups|
      groups.select { |g| g.domains.detect {|d| d == 'nomanager' } }
    end.should be_false
  end

  it 'should add associations to node' do
    perms = subject.permissions([Group.new('admin', ["german", "french"])]) do |resource, groups|
      if groups && groups.first && groups.first.name == 'admin'
        groups.first.domains
      else
        {}
      end
    end

    expected = {}
    expected[:accounts] = {
      :permission=>{
        :resource=>"accounts", 
        :actions=>[{:action=>{ 
                       :name=>"destroy",
                       :associations=>["german", "french"]}}], 
        :deny=>false}
    }
    expected[:allow_all_defaults] = {
      :permission=>{
        :resource=>"allow_all_defaults",
        :actions=>[{:action=>{:name=>"index"}}], 
        :deny=>true, 
        :associations=>["german", "french"]}
    }
    expected[:defaults] = {
      :permission=>{
        :resource=>"defaults", 
        :actions=>[{:action=>{
                       :name=>"index",
                       :associations=>["german", "french"]}}], 
        :deny=>false}
    }
    expected[:no_defaults] = {
      :permission=>{
        :resource=>"no_defaults", 
        :actions=>[{:action=>{
                       :name=>"index",
                       :associations=>["german", "french"]}}], 
        :deny=>false}
    } 
    expected[:only_defaults] = {
      :permission=>{
        :resource=>"only_defaults", 
        :actions=>[],
        :associations=>["german", "french"],
        :deny=>true}
    }
    expected[:person]= {
      :permission=>{
        :resource=>"person", 
        :actions=> [{:action=>{ 
                        :name=>"destroy",
                        :associations=>["german", "french"]}}, 
                    {:action=>{ 
                        :name=>"index",
                        :associations=>["german", "french"]}}], 
        :deny=>false}
    }
    expected[:regions] = {
      :permission=>{
        :resource=>"regions",
        :actions=>[
                   {:action=>{:name=>"create", :associations=>["german", "french"]}},
                   {:action=>{:name=>"show", :associations=>["german", "french"]}}
                  ],
        :deny=>false}
    }
    expected[:users] = {
      :permission=>{
        :resource=>"users", 
        :actions=>[], 
        :deny=>false}
    }
    perms.each do |perm|
      attr = perm.attributes
      attr[ :actions ] = perm.actions.collect do |a| 
        aa = a.attributes
        aa.delete( :associations ) if aa[ :associations ].nil?
        {:action => aa}
      end
      attr[:actions].sort!{ |n,m| n[:action][:name] <=> m[:action][:name] }
      attr.delete( :associations ) if attr[ :associations ].nil?
      expected[perm[:resource].to_sym][:permission].should == attr
    end
  end
end

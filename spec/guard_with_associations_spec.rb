require 'spec_helper'
require 'ixtlan/guard/guard_ng'
require 'logger'

class Group

  attr_accessor :name, :domains

  def initialize(name, *domains)
    @name = name
    @domains = domains.flatten
  end
end

describe Ixtlan::Guard::GuardNG do

  subject do
    logger = Logger.new(STDOUT)
    def logger.debug(&block)
     # info("\n\t[debug] " + block.call)
    end
    Ixtlan::Guard::GuardNG.new(:guards_dir => File.join(File.dirname(__FILE__), "guards"), :logger => logger )
  end

  it 'should pass without association without block' do
    subject.allowed?(:users, :update, [Group.new(:users)]).should be_true
  end

  it 'should deny without association with block' do
    subject.allowed?(:users, :update, [Group.new(:users)]){}.should be_false
  end

  it 'should deny with association without block' do
    subject.allowed?(:users, :update, [Group.new(:users, :manager)], :manager).should be_false
  end

  it 'should pass with matching association with block' do
    subject.allowed?(:users, :update, [Group.new(:users, :manager)], :manager) do |group, association|
      group.domains.detect {|d| d == association.to_s }
    end.should be_false
  end

  it 'should fail with mismatching association with block' do
    subject.allowed?(:users, :update, [Group.new(:users, :manager)], :nomanager) do |group, association|
      group.domains.detect {|d| d == association }
    end.should be_false
  end

  it 'should add associations to node' do
    subject.permissions([Group.new('admin', [:german, :french])]) do |resource, action, groups|
      if groups && groups.first && groups.first.name == 'admin'
        { :domains => groups.first.domains }
      else
        {}
      end
    end.sort { |m,n| m[:resource] <=> n[:resource]}.should == 
      [{
         :permission=>{
           :resource=>"accounts", 
           :actions=>[{:action=>{ 
                          :name=>"destroy",
                          :domains=>[:german, :french]}}], 
           :deny=>false}},
       {
         :permission=>{
           :resource=>"allow_all_defaults",
           :actions=>[{:action=>{:name=>"index"}}], 
           :deny=>true, 
           :domains=>[:german, :french]}},
       {
         :permission=>{
           :resource=>"defaults", 
           :actions=>[{:action=>{
                          :name=>"index",
                          :domains=>[:german, :french]}}], 
           :deny=>false}}, 
       {
         :permission=>{
           :resource=>"no_defaults", 
           :actions=>[{:action=>{
                          :name=>"index",
                          :domains=>[:german, :french]}}], 
           :deny=>false}}, 
       {
         :permission=>{
           :resource=>"only_defaults", 
           :domains=>[:german, :french],
           :actions=>[],
           :deny=>true}}, 
       {
         :permission=>{
           :resource=>"person", 
           :actions=> [{:action=>{ 
                           :name=>"destroy",
                           :domains=>[:german, :french]}}, 
                       {:action=>{ 
                           :name=>"index",
                           :domains=>[:german, :french]}}], 
           :deny=>false}},
       {
          :permission=>{
            :resource=>"regions",
            :actions=>[
              {:action=>{:name=>"show", :domains=>[:german, :french]}},
              {:action=>{:name=>"create", :domains=>[:german, :french]}}
            ],
            :deny=>false}},
       {
         :permission=>{
           :resource=>"users", 
           :actions=>[], 
           :deny=>false}}]  
  end
end

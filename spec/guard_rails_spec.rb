require 'spec_helper'
require 'ixtlan/guard/guard'
require 'ixtlan/guard/guard_rails'
require 'logger'
class Logger
  def debug(&block)
  end
end

class Rails
  def self.application
    self
  end
  def self.config
    self
  end
  def self.guard
      @guard ||= 
        begin
          logger = Logger.new(STDOUT)
          Ixtlan::Guard::Guard.new(:guards_dir => File.join(File.dirname(__FILE__), "guards"), 
                                   :logger => logger)
        end
  end
end

class Controller
  include Ixtlan::Guard::ActionController

  attr_accessor :params
  def new_user
    user = Object.new
    def user.groups(groups = ['users'])
      @groups ||= groups
    end
    user
  end
  def current_user
    @user ||= new_user
  end
end
class RestrictedController < Controller

  guard_filter :only => [:index] do |groups|
    groups.select {|g| g =~ /^user/ }
  end

  guard_filter :except => [:index] do |groups|
    groups.select {|g| g == 'admin' }
  end

  
end

describe Ixtlan::Guard::ActionController do

  describe "without filter" do
    subject do
      Controller.new
    end
    
    it 'should return a guard' do
      subject.send(:guard).should_not be_nil
    end

    it 'should have current_groups' do
      subject.send(:current_groups).should_not be_nil
    end

    it 'should have no guard_filters' do
      subject.class.guard_filters.should == []
    end

    it 'raise error on unknown resource' do
      lambda{subject.send(:check, "edit", "unknown_resource")}.should raise_error( Ixtlan::Guard::GuardException)
    end
    
    it 'should pass' do
      subject.send(:check, "index", "users").should == ["users"]
      begin
        subject.params = {:controller => "users", :action => "index" }
        subject.send(:authorize).should be_true
        subject.params.delete(:action)
        subject.send(:allowed?, "index").should be_true
      ensure
        subject.params = {}
      end
    end

    it 'should not pass' do
      subject.send(:check, "doit", "no_defaults").should be_nil
      begin
        subject.params = {:controller => "no_defaults", :action => "doit" }
        lambda{subject.send(:authorize)}.should raise_error(Ixtlan::Guard::PermissionDenied)
        subject.params.delete(:action)
        subject.send(:allowed?, "doitagain").should be_false
      ensure
        subject.params = {}
      end
    end
  end  

  describe "with filter" do
    subject do
      c = RestrictedController.new
      c.current_user.groups ['users', 'useradmin', 'admin']
      c
    end
    
    it 'should return a guard' do
      subject.send(:guard).should_not be_nil
    end

    it 'should have current_groups' do
      subject.send(:current_groups).should_not be_nil
    end

    it 'should have no guard_filters' do
      subject.class.guard_filters.size.should == 2
    end

    it 'raise error on unknown resource' do
      lambda{subject.send(:check, "edit", "unknown_resource")}.should raise_error( Ixtlan::Guard::GuardException)
    end
    
    it 'should pass' do
      subject.send(:check, "destroy", "person").should == ["admin"]
      begin
        subject.params = {:controller => "person", :action => "destroy" }
        subject.send(:authorize).should be_true
        subject.params.delete(:action)
        subject.send(:allowed?, "destroy").should be_true
      ensure
        subject.params = {}
      end
    end

    it 'should not pass' do
      subject.send(:check, "edit", "person").should be_nil
      begin
        subject.params = {:controller => "person", :action => "edit" }
        lambda{subject.send(:authorize)}.should raise_error(Ixtlan::Guard::PermissionDenied)
        subject.params.delete(:action)
        subject.send(:allowed?, "edit").should be_false
      ensure
        subject.params = {}
      end
    end
  end
end

require 'spec_helper'
require 'ixtlan/guard'

describe Ixtlan::Guard do

  before :all do
    @guard = Ixtlan::Guard.new(Logger.new(STDOUT), 
                               :root, 
                               File.join(File.dirname(__FILE__), "guards") )

    @guard.setup
    @current_user = Object.new
    def @current_user.groups(g = nil)
      @g = g if g
      @g || []
    end

    @controller = Object.new
    def @controller.current_user(u = nil)
      @u = u if u
      @u
    end
    @controller.current_user( @current_user )
  end

  it 'should fail with missing guard dir' do
    lambda {Ixtlan::Guard.new(Logger.new(STDOUT), 
                              :root, 
                              "does_not_exists").setup }.should raise_error(Ixtlan::GuardException)
  end

  it 'should initialize' do
    @guard.should_not be_nil
  end

  it 'should pass check without user' do
    controller = Object.new
    def controller.current_user
    end
    @guard.check(controller, :none, :something).should be_true
  end

  it 'should pass check with user being root' do
    @current_user.groups([:root])
    @guard.check(@controller, :users, :show).should be_true
  end

  it 'should not pass check with user - no groups' do
    @current_user.groups([])
    @guard.check(@controller, :users, :show).should be_false
  end

  it 'should pass unguarded check with user - no groups' do
    @current_user.groups([])
    @guard.check(@controller, :users, :index).should be_true
  end

  it 'should pass check with user on aliased action' do
    @current_user.groups([:users])
    @guard.check(@controller, :users, :edit).should be_true
  end

  it 'should pass check with user' do
    @current_user.groups([:users])
    @guard.check(@controller, :users, :update).should be_true
  end

  it 'should not pass check with user' do
    @current_user.groups([:accounts])
    @guard.check(@controller, :users, :update).should be_false
  end

  it 'should pass check with user with passing extra check' do
    @current_user.groups([:users])
    @guard.check(@controller, :users, :update) do |g|
      true
    end.should be_true
  end

  it 'should not pass check with user with failing extra check' do
    @current_user.groups([:users])
    @guard.check(@controller, :users, :update) do |g|
      false
    end.should be_false
  end

  it 'should raise exception on unknown action' do
    lambda {@guard.check(@controller, :users, :unknown_action) }.should raise_error(Ixtlan::GuardException)
  end

  it 'should raise exception on unknown resource' do
    lambda {@guard.check(@controller, :unknown_resource, :update) }.should raise_error(Ixtlan::GuardException)
  end
end

require 'spec_helper'
require 'ixtlan/guard'

describe Ixtlan::Guard do

  before :all do
    @guard = Ixtlan::Guard::Guard.new(:guard_dir => File.join(File.dirname(__FILE__), "guards") )

    @guard.setup
    @current_user = Object.new
    def @current_user.groups(g = nil)
      if g
        @groups = g.collect do |gg|
          group = Object.new
          def group.name(name =nil)
            @name = name if name
            @name
          end
          group.name(gg)
          group
        end
      end
      @groups || []
    end

    @controller = Object.new
    def @controller.current_user(u = nil)
      @u = u if u
      @u
    end
    @controller.current_user( @current_user )
  end

  it 'should fail with missing guard dir' do
    lambda {Ixtlan::Guard::Guard.new(:guard_dir => "does_not_exists").setup }.should raise_error(Ixtlan::Guard::GuardException)
  end

  it 'should initialize' do
    @guard.should_not be_nil
  end

  it 'should fail check without current user' do
    controller = Object.new
    def controller.current_user
    end
    @guard.check(controller, :none, :something).should be_false
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

  it 'should not pass check with user when in blocked group' do
    @current_user.groups([:users])
    @guard.block_groups([:users])
    begin
      @guard.check(@controller, :users, :update).should be_false
    ensure
      @guard.block_groups([])
    end
  end

  it 'should pass check with user when not in blocked group' do
    @current_user.groups([:users])
    @guard.block_groups([:accounts])
    begin
      @guard.check(@controller, :users, :update).should be_true
    ensure
      @guard.block_groups([])
    end
  end

  it 'should pass check with root-user when not in blocked group' do
    @current_user.groups([:root])
    @guard.block_groups([:root])
    begin
      @guard.check(@controller, :users, :update).should be_true
    ensure
      @guard.block_groups([])
    end
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
    lambda {@guard.check(@controller, :users, :unknown_action) }.should raise_error(Ixtlan::Guard::GuardException)
  end

  it 'should raise exception on unknown resource' do
    lambda {@guard.check(@controller, :unknown_resource, :update) }.should raise_error(Ixtlan::Guard::GuardException)
  end
end

require 'spec_helper'
require 'ixtlan/guard/guard'
require 'logger'

describe Ixtlan::Guard::Guard do

  subject do
    logger = Logger.new(STDOUT)
    def logger.debug(&block)
      #info("\n\t[debug] " + block.call)
    end
    Ixtlan::Guard::Guard.new(:guards_dir => File.join(File.dirname(__FILE__), "guards"), :logger => logger )
  end

  it 'should fail with missing guard dir' do
    lambda {Ixtlan::Guard::Guard.new(:guards_dir => "does_not_exists") }.should raise_error(Ixtlan::Guard::GuardException)
  end

  it 'should initialize' do
    subject.should_not be_nil
  end

  it 'should fail without groups' do
    subject.allowed?(:users, :something, []).should be_false
  end

  it 'should pass with user being root' do
    subject.allowed?(:users, :show, [:root]).should be_true
  end

  it 'should pass "allow all groups" with any groups' do
    # users resource ask for a block since it is restricted
    subject.allowed?(:users, :index, [:any_possible_group]){|g| g}.should be_true
    subject.allowed?(:only_defaults, :index, [:any_possible_group]).should be_true
  end

  it 'should pass' do
    # users resource ask for a block since it is restricted
    subject.allowed?(:users, :update, [:users]){|g| g}.should be_true
    subject.allowed?(:only_defaults, :update, [:users]).should be_true
    subject.allowed?(:allow_all_defaults, :update, [:users]).should be_true
  end

  it 'should not pass with user when in blocked group' do
    subject.block_groups([:users])
    begin
      # users resource ask for a block since it is restricted
      subject.allowed?(:users, :update, [:users]){|g| g}.should be_false
      subject.allowed?(:only_defaults, :update, [:users]).should be_false
    subject.allowed?(:allow_all_defaults, :update, [:users]).should be_false
    ensure
      subject.block_groups([])
    end
  end

  it 'should pass with user when not in blocked group' do
    subject.block_groups([:accounts])
    begin
      # users resource ask for a block since it is restricted
      subject.allowed?(:users, :update, [:users]){|g| g}.should be_true
      subject.allowed?(:only_defaults, :update, [:users]).should be_true
      subject.allowed?(:allow_all_defaults, :update, [:users]).should be_true
    ensure
      subject.block_groups([])
    end
  end

  it 'should not block root group' do
    subject.block_groups([:root])
    begin
      # users resource ask for a block since it is restricted
      subject.allowed?(:users, :update, [:root]){|g| g}.should be_true
      subject.allowed?(:only_defaults, :update, [:root]).should be_true
    subject.allowed?(:allow_all_defaults, :update, [:root]).should be_true
    ensure
      subject.block_groups([])
    end
  end

  it 'should not pass' do
    subject.allowed?(:users, :update, [:accounts]).should be_false
    subject.allowed?(:allow_all_defaults, :index, [:users]).should be_false
  end

  it 'should should use defaults on unknown action' do
      # users resource ask for a block since it is restricted
    subject.allowed?(:users, :unknow, [:users]){|g| g}.should be_true
    subject.allowed?(:only_defaults, :unknow, [:users]).should be_true
    subject.allowed?(:allow_all_defaults, :update, [:users]).should be_true
  end

end

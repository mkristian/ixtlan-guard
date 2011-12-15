require 'spec_helper'
require 'ixtlan/guard/guard_ng'
require 'logger'

describe Ixtlan::Guard::GuardNG do

  subject do
    logger = Logger.new(STDOUT)
    def logger.debug(&block)
      #info("\n\t[debug] " + block.call)
    end
    Ixtlan::Guard::GuardNG.new(:guards_dir => File.join(File.dirname(__FILE__), "guards"), :logger => logger )
  end

  it 'should fail with missing guard dir' do
    lambda {Ixtlan::Guard::GuardNG.new(:guards_dir => "does_not_exists") }.should raise_error(Ixtlan::Guard::GuardException)
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

  it 'should pass "allow all groups" with user with any groups' do
    subject.allowed?(:users, :index, [:any_possible_group]).should be_true
    subject.allowed?(:only_defaults, :index, [:any_possible_group]).should be_true
  end

  it 'should pass' do
    subject.allowed?(:users, :update, [:users]).should be_true
    subject.allowed?(:only_defaults, :update, [:users]).should be_true
    subject.allowed?(:allow_all_defaults, :update, [:users]).should be_true
  end

  it 'should not pass with user when in blocked group' do
    subject.block_groups([:users])
    begin
      subject.allowed?(:users, :update, [:users]).should be_false
      subject.allowed?(:only_defaults, :update, [:users]).should be_false
    subject.allowed?(:allow_all_defaults, :update, [:users]).should be_false
    ensure
      subject.block_groups([])
    end
  end

  it 'should pass with user when not in blocked group' do
    subject.block_groups([:accounts])
    begin
      subject.allowed?(:users, :update, [:users]).should be_true
      subject.allowed?(:only_defaults, :update, [:users]).should be_true
      subject.allowed?(:allow_all_defaults, :update, [:users]).should be_true
    ensure
      subject.block_groups([])
    end
  end

  it 'should not block root group' do
    subject.block_groups([:root])
    begin
      subject.allowed?(:users, :update, [:root]).should be_true
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
    subject.allowed?(:users, :unknow, [:users]).should be_true
    subject.allowed?(:only_defaults, :unknow, [:users]).should be_true
    subject.allowed?(:allow_all_defaults, :update, [:users]).should be_true
  end

end

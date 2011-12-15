require 'spec_helper'
require 'ixtlan/guard/guard_ng'
require 'logger'
require 'fileutils'

$target = File.join("target", "guards", "users_guard.yml")
FileUtils.mkdir_p(File.dirname($target))
$source1 = File.join(File.dirname(__FILE__), "guards", "users1_guard.yml")
$source2 = File.join(File.dirname(__FILE__), "guards", "users2_guard.yml")
$logger = Logger.new(STDOUT)
def $logger.debug(&block)
#  info("\n\t[debug] " + block.call)
end

describe Ixtlan::Guard::GuardNG do

  context "without caching" do
    def not_cached
      $not_cached ||= Ixtlan::Guard::GuardNG.new(:guards_dir => File.dirname($target), 
                                                 :logger => $logger )
    end
      
    subject { not_cached }

    it 'should pass' do
      FileUtils.cp($source1, $target)
      subject.allowed?(:users, :index, [:users]).should be_true
      subject.allowed?(:users, :index, [:admin]).should be_false
    end

    it 'should not pass' do
      FileUtils.cp($source2, $target)
      subject.allowed?(:users, :index, [:users]).should be_false
      subject.allowed?(:users, :index, [:admin]).should be_true
    end
  end

  context "with caching" do
    def cached
      $cached ||= Ixtlan::Guard::GuardNG.new(:guards_dir => File.dirname($target), 
                                             :logger => $logger,
                                             :cache => true)
    end
    subject { cached }

    it 'should pass' do
      FileUtils.cp($source1, $target)
      subject.allowed?(:users, :index, [:users]).should be_true
      subject.allowed?(:users, :index, [:admin]).should be_false
    end

    it 'should not pass' do
      FileUtils.cp($source2, $target)
      subject.allowed?(:users, :index, [:users]).should be_true
      subject.allowed?(:users, :index, [:admin]).should be_false
    end
  end
end

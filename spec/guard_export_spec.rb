require 'spec_helper'
require 'ixtlan/guard/guard_ng'
require 'logger'

describe Ixtlan::Guard::GuardNG do

  subject do
    logger = Logger.new(STDOUT)
    def logger.debug(&block)
      info("\n\t[debug] " + block.call)
    end
    Ixtlan::Guard::GuardNG.new(:guards_dir => File.join(File.dirname(__FILE__), "guards"), :logger => logger )
  end

  it 'should export permission' do
    subject.permissions(['admin']).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>{}, "index"=>{}}, "accounts"=>{"defaults"=>nil, "destroy"=>{}, "show"=>nil}}

    subject.permissions(['manager']).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>nil, "index"=>{}}, "accounts"=>{"defaults"=>nil, "destroy"=>nil, "show"=>{}}}

    subject.permissions(['manager', 'admin']).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>{}, "index"=>{}}, "accounts"=>{"defaults"=>nil, "destroy"=>{}, "show"=>{}}}

    subject.permissions(['users']).should == {"users"=>{"defaults"=>{}}, "person"=>{"defaults"=>nil, "destroy"=>nil, "index"=>nil}, "accounts"=>{"defaults"=>nil, "destroy"=>nil, "show"=>nil}}
  end

  it 'should export permission with flavor' do

    flavors = { 'admin' => ['example', 'dummy'], 'manager' => ['example', 'master'] }

    domains = Proc.new do |groups|
      groups.collect do |g|
        flavors[g] || []
      end.flatten.uniq
    end

    subject.permissions(['admin'], 'domains' => domains).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>{'domains'=>["example", "dummy"]}, "index"=>{'domains'=>["example", "dummy"]}}, "accounts"=>{"defaults"=>nil, "destroy"=>{'domains'=>["example", "dummy"]}, "show"=>nil}}

    subject.permissions(['manager'], 'domains' => domains).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>nil, "index"=>{"domains"=>["example", "master"]}}, "accounts"=>{"defaults"=>nil, "destroy"=>nil, "show"=>{"domains"=>["example", "master"]}}}

    subject.permissions(['manager', 'admin'], 'domains' => domains).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>{"domains"=>["example", "dummy"]}, "index"=>{"domains"=>["example", "master", "dummy"]}}, "accounts"=>{"defaults"=>nil, "destroy"=>{"domains"=>["example", "dummy"]}, "show"=>{"domains"=>["example", "master"]}}}

    subject.permissions(['users'], 'domains' => domains).should == {"users"=>{"defaults"=>{}}, "person"=>{"defaults"=>nil, "destroy"=>nil, "index"=>nil}, "accounts"=>{"defaults"=>nil, "destroy"=>nil, "show"=>nil}}
  end
end

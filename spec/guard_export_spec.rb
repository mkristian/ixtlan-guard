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
  
  context '#permissions' do
    
    it 'should deny all without defaults but wildcard "*" actions' do
      subject.permissions(['unknown_group']).should == [
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}},
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         {:permission=>
           {
             :resource=>"no_defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         {
           :permission=>
           {
             :resource=>"defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         #allow nothing
         {:permission=>{:resource=>"person", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>false}},
         # allow anything but index
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[{:action=>{:name=>"index"}}], :deny=>true}}]
    end
    it 'should deny some without defaults but wildcard "*" actions' do
      subject.permissions(['no_admin']).should == [
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}},
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         {:permission=>
           {
             :resource=>"no_defaults",
             :actions=>
             [{:action=>{:name=>"edit"}},
              {:action=>{:name=>"index"}},
              {:action=>{:name=>"show"}}],
             :deny=>false #allow
           }
         },
         {
           :permission=>
           {
             :resource=>"defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         #allow nothing
         {:permission=>{:resource=>"person", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>false}},
         # allow anything but index
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[{:action=>{:name=>"index"}}], :deny=>true}}]
    end
    it 'should allow "root"' do
      subject.permissions(['root']).should == [
         {:permission=>{:resource=>"users", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"no_defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"person", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[], :deny=>true}}]
    end   
    it 'should allow with default group' do
      subject.permissions(['_master']).should == [
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}},
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         {:permission=>
           {
             :resource=>"no_defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         {
           :permission=>
           {
             :resource=>"defaults",
             :actions=>[{:action=>{:name=>"show"}}, 
                          {:action=>{:name=>"destroy"}}],
             :deny=>true
           }
         },
         #allow nothing
         {:permission=>{:resource=>"person", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>false}},
         # allow anything but index
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[{:action=>{:name=>"index"}}], :deny=>true}}]
    end 
    it 'should allow with non-default group' do
      subject.permissions(['_admin']).should == [
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}},
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         {:permission=>
           {
             :resource=>"no_defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         {
           :permission=>
           {
             :resource=>"defaults",
             :actions=>[{:action=>{:name=>"edit"}}, 
                        {:action=>{:name=>"index"}}, 
                        {:action=>{:name=>"show"}}],
             :deny=>false # allow
           }
         },
         #allow nothing
         {:permission=>{:resource=>"person", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>false}},
         # allow anything but index
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[], :deny=>true}}]
    end
  end

  context '#permission_map' do
    it 'should export' do
      pending "check expectations before implementing specs"
      subject.permission_map(['admin']).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>{}, "index"=>{}}, "accounts"=>{"defaults"=>nil, "destroy"=>{}, "show"=>nil}}
      
      subject.permission_map(['manager']).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>nil, "index"=>{}}, "accounts"=>{"defaults"=>nil, "destroy"=>nil, "show"=>{}}}
      
      subject.permission_map(['manager', 'admin']).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>{}, "index"=>{}}, "accounts"=>{"defaults"=>nil, "destroy"=>{}, "show"=>{}}}
      
      subject.permission_map(['users']).should == {"users"=>{"defaults"=>{}}, "person"=>{"defaults"=>nil, "destroy"=>nil, "index"=>nil}, "accounts"=>{"defaults"=>nil, "destroy"=>nil, "show"=>nil}}
    end
    
    it 'should export with flavor' do
      pending "check expectations before implementing specs"
      
      flavors = { 'admin' => ['example', 'dummy'], 'manager' => ['example', 'master'] }
      
      domains = Proc.new do |groups|
        groups.collect do |g|
          flavors[g] || []
        end.flatten.uniq
      end
      
      subject.permission_map(['admin'], 'domains' => domains).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>{'domains'=>["example", "dummy"]}, "index"=>{'domains'=>["example", "dummy"]}}, "accounts"=>{"defaults"=>nil, "destroy"=>{'domains'=>["example", "dummy"]}, "show"=>nil}}
      
      subject.permission_map(['manager'], 'domains' => domains).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>nil, "index"=>{"domains"=>["example", "master"]}}, "accounts"=>{"defaults"=>nil, "destroy"=>nil, "show"=>{"domains"=>["example", "master"]}}}
      
      subject.permission_map(['manager', 'admin'], 'domains' => domains).should == {"users"=>{"defaults"=>nil}, "person"=>{"defaults"=>nil, "destroy"=>{"domains"=>["example", "dummy"]}, "index"=>{"domains"=>["example", "master", "dummy"]}}, "accounts"=>{"defaults"=>nil, "destroy"=>{"domains"=>["example", "dummy"]}, "show"=>{"domains"=>["example", "master"]}}}
      
      subject.permission_map(['users'], 'domains' => domains).should == {"users"=>{"defaults"=>{}}, "person"=>{"defaults"=>nil, "destroy"=>nil, "index"=>nil}, "accounts"=>{"defaults"=>nil, "destroy"=>nil, "show"=>nil}}
    end
  end
end

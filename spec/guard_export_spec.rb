require 'spec_helper'
require 'ixtlan/guard/guard_ng'
require 'logger'

describe Ixtlan::Guard::GuardNG do

  subject do
    logger = Logger.new(STDOUT)
    def logger.debug(&block)
   #   info("\n\t[debug] " + block.call)
    end
    Ixtlan::Guard::GuardNG.new(:guards_dir => File.join(File.dirname(__FILE__), "guards"), :logger => logger )
  end
  
  context '#permissions' do
    
    it 'should deny all without defaults but wildcard "*" actions' do
      subject.permissions(['unknown_group']).sort { |n,m| n[:resource] <=> m[:resource] }.should == [
         #allow nothing
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>false}},
         # allow anything but index
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[{:action=>{:name=>"index"}}], :deny=>true}},
         {:permission=>
           {
             :resource=>"defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         {:permission=>
           {
             :resource=>"no_defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         #allow nothing
         {:permission=>{:resource=>"person", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"regions", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}}]
    end
    it 'should deny some without defaults but wildcard "*" actions' do
      subject.permissions(['no_admin']).sort { |n,m| n[:resource] <=> m[:resource] }.should == [
         #allow nothing
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>false}},
         # allow anything but index
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[{:action=>{:name=>"index"}}], :deny=>true}},
         {:permission=>
           {
             :resource=>"defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
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
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         #allow nothing
         {:permission=>{:resource=>"person", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"regions", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}}]
    end
    it 'should allow "root"' do
      subject.permissions(['root']).sort { |n,m| n[:resource] <=> m[:resource] }.should == [
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"no_defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"person", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"regions", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"users", :actions=>[], :deny=>true}}]
    end   
    it 'should allow with default group' do
      subject.permissions(['_master']).sort { |n,m| n[:resource] <=> m[:resource] }.should == [
         #allow nothing
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>false}},
         # allow anything but index
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[{:action=>{:name=>"index"}}], :deny=>true}},
         {:permission=>
           {
             :resource=>"defaults",
             :actions=>[{:action=>{:name=>"show"}},
                        {:action=>{:name=>"destroy"}}],
             :deny=>true
           }
         },
         {:permission=>
           {
             :resource=>"no_defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         #allow nothing
         {:permission=>{:resource=>"person", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"regions", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}}]
    end

    it 'should allow with non-default group' do
      subject.permissions(['_admin']).sort { |n,m| n[:resource] <=> m[:resource] }.should == [
         #allow nothing
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>false}},
         # allow anything but index
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[], :deny=>true}},
         {:permission=>
           {
             :resource=>"defaults",
             :actions=>[{:action=>{:name=>"edit"}}, 
                        {:action=>{:name=>"index"}}, 
                        {:action=>{:name=>"show"}}],
             :deny=>false # allow
           }
         },
         {:permission=>
           {
             :resource=>"no_defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         #allow nothing
         {:permission=>{:resource=>"person", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"regions", :actions=>[], :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}}]
    end

    it 'should allow with association' do
      group = Object.new
      def group.name
        "region"
      end
      subject.permissions([group])do |resource, action, groups|
        if resource == 'regions'
          case action
          when 'show'
            {:associations => [:europe, :asia]}
          else
            {}
          end
        else
          {}
        end
      end.sort { |n,m| n[:resource] <=> m[:resource] }.should == [
         #allow nothing
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>false}},
         # allow anything but index
         {:permission=>
           {
              :resource=>"allow_all_defaults",
              :actions=>[{:action=>{:name=>"index"}}],
              :deny=>true
           }
         },
         {:permission=>
           {
             :resource=>"defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false # allow
           }
         },
         {:permission=>
           {
             :resource=>"no_defaults",
             :actions=>[{:action=>{:name=>"index"}}],
             :deny=>false #allow
           }
         },
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         #allow nothing
         {:permission=>{:resource=>"person", :actions=>[], :deny=>false}},

         {:permission=>
          {:resource=>"regions",
           :actions=>
            [{:action=>{:name=>"show", :associations=>[:europe, :asia]}},
             {:action=>{:name=>"create"}}],
           :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}}]
    end
  end
end

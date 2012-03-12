require 'spec_helper'
require 'ixtlan/guard/guard'
require 'logger'

describe Ixtlan::Guard::Guard do

  def assert(expected, perms)
    map = {}
    expected.each do |e|
      map[e[:permission][:resource]] = e
      if e[:permission][:actions]
        e[:permission][:actions].sort!{ |n,m| n[:action][:name] <=> m[:action][:name] }
      end
    end
    perms.each do |perm|
      if perm[:actions]
        perm[:actions].sort!{ |n,m| n.content[:name] <=> m.content[:name] }
      end
      map[perm[:resource].to_s].should == perm
    end
  end

  subject do
    logger = Logger.new(STDOUT)
    def logger.debug(&block)
   #   info("\n\t[debug] " + block.call)
    end
    Ixtlan::Guard::Guard.new(:guards_dir => File.join(File.dirname(__FILE__), "guards"), :logger => logger )
  end
  
  context '#permissions' do
    
    it 'should deny all without defaults but wildcard "*" actions' do
      perm = subject.permissions(['unknown_group'])
      expected = [
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

      assert(expected, perm)
    end
    it 'should deny some without defaults but wildcard "*" actions' do
      perm = subject.permissions(['no_admin'])
      expected = [
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

      assert(expected, perm)
    end
    it 'should allow "root"' do
      perm = subject.permissions(['root'])
      expected = [
         {:permission=>{:resource=>"accounts", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"allow_all_defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"no_defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"only_defaults", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"person", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"regions", :actions=>[], :deny=>true}},
         {:permission=>{:resource=>"users", :actions=>[], :deny=>true}}]

      assert(expected, perm)
    end

    it 'should allow with default group' do
      perm = subject.permissions(['_master'])
      expected = [
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

      assert(expected, perm)
    end

    it 'should allow with non-default group' do
      perm = subject.permissions(['_admin'])
      expected = [
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

      assert(expected, perm)
    end

    it 'should allow with association' do
      group = Object.new
      def group.name
        "region"
      end
      perm = subject.permissions([group])do |resource, groups|
        if resource == 'regions'
          [:europe, :asia]
        end
      end
      expected = [
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
             {:action=>{:name=>"create", :associations=>[:europe, :asia]}}],
           :deny=>false}},
         #allow nothing
         {:permission=>{:resource=>"users", :actions=>[], :deny=>false}}]

      assert(expected, perm)
    end
  end
end

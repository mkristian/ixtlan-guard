shared_examples_for 'integration-test' do

  describe "UserManagementModels" do

    before :all do
      @root = Group.find_by_name(Group::ROOT) || Group.create(:name => Group::ROOT)
      @admin = Group.find_by_name(Group::ADMIN) || Group.create(:name => Group::ADMIN)
      @translator = Group.find_by_name("translator") || Group.create(:name => "translator")
      @superuser = User.find_by_id(1) || User.create!(:groups => [@root])
      @main = Domain.find_by_name('main') || Domain.create(:name => 'main')
      @sub = Domain.find_by_name('sub') || Domain.create(:name => 'sub')
      DomainsGroupsUser.delete_all
      @adminuser = User.new('group_ids' => [@admin.id])
      @adminuser.current_user = @superuser
      @adminuser.save
    end

    describe "root user" do
      it 'should create user by root' do
        @adminuser.id.should_not be_nil
        @adminuser.groups.should == [@admin]
        @adminuser.domains_for_group(@admin).should == []
      end

      it 'should add domain to user via update by root' do
        @adminuser.domains_for_group(@admin).member?(@main).should be_false
        @adminuser.current_user = @superuser
        @adminuser.update_attributes(Group::ADMIN => { 'domain_ids' => [@main.id.to_s] }, 'group_ids' => [@admin.id.to_s])
        @adminuser.domains_for_group(@admin).member?(@main).should be_true
        @adminuser.current_user.should be_nil
      end

      it 'should raise error when adding a domain without current_user set' do
        @adminuser.current_user = nil
        lambda { @adminuser.update_attributes(Group::ADMIN => { 'domain_ids' => [@sub.id.to_s] }, 'group_ids' => [@admin.id.to_s]) }.should raise_error
        @adminuser.current_user.should be_nil
      end

      it 'should add new group through update' do
        @adminuser.groups.member?(@translator).should be_false
        @adminuser.current_user = @superuser
        @adminuser.update_attributes('group_ids' => [@translator.id.to_s])
        @adminuser.groups.member?(@translator).should be_true
      end

      it 'should raise error when adding new group' do
        @adminuser.groups.member?(@root).should be_false
        @adminuser.current_user = nil
        lambda{ @adminuser.update_attributes('group_ids' => [@translator.id.to_s])}.should raise_error
        @adminuser.current_user.should be_nil
      end
    end

    describe "admin user" do

      before :all do
        @locales = Group.find_by_name("locales") || Group.create(:name => "locales")
        @adminuser.current_user = @superuser
        @adminuser.update_attributes('group_ids' => [@admin.id.to_s, @locales.id.to_s], Group::ADMIN => {"domain_ids" => [@main.id.to_s]})
        @adminuser.save
      end

      it 'should create new users' do
        user = User.new('group_ids' => [@admin.id.to_s])
        user.current_user = @adminuser
        user.save.should be_true
        user.groups.member?(@admin).should be_true
        user.groups.size.should == 1
      end

      it 'should not add group via update_attributes which admin does not belong to' do
        user = User.create({:current_user => @adminuser, 'group_ids' => [@root.id.to_s]})
        user.id.should_not be_nil

        user.groups.member?(@root).should be_false
        user.groups.size.should == 0
      end

      it 'should not add group via update_attributes which admin does not belong to' do
        user = User.create(:current_user => @adminuser)
        user.id.should_not be_nil

        user.current_user = @adminuser
        user.update_attributes('group_ids' => [@root.id.to_s]).should be_true

        user.groups.member?(@root).should be_false
        user.groups.size.should == 0
      end

      it 'should be able to delete only groups belonging to admin, leave others alone' do
        user = User.create(:current_user => @superuser, 'group_ids' => [@translator.id.to_s])
        user.groups.member?(@translator).should be_true

        user.current_user = @adminuser
        user.update_attributes('group_ids' => []).should be_true

        user.groups.member?(@translator).should be_true
        user.groups.size.should == 1
      end

      it 'should be able to add and delete groups belonging to admin' do
        user = User.create(:current_user => @superuser, 'group_ids' => [@translator.id.to_s])
        user.id.should_not be_nil
        user.groups.member?(@translator).should be_true

        user.current_user = @adminuser
        user.update_attributes('group_ids' => [@admin.id.to_s, @locales.id.to_s]).should be_true

        user.groups.member?(@translator).should be_true
        user.groups.size.should == 3

        user.current_user = @adminuser
        user.update_attributes('group_ids' => [@locales.id.to_s]).should be_true

        user.groups.member?(@locales).should be_true
        user.groups.member?(@translator).should be_true
        user.groups.size.should == 2
      end 

      it 'should create new users with domains' do
        # first create to have an ID
        user = User.create(:current_user => @adminuser)
        user.id.should_not be_nil
        # then add the domain
        user.update_attributes(:current_user => @adminuser, 'group_ids' => [@admin.id.to_s], "admin" => {"domain_ids" => [@main.id.to_s] })

        user.groups.member?(@admin).should be_true
        user.groups.size.should == 1

        user.domains_for_group(@admin).member?(@main).should be_true
        user.domains_for_group(@admin).size.should == 1
      end
      
      it 'should add only domains which belongs to admin' do
        # first create to have an ID
        user = User.create(:current_user => @adminuser, 'group_ids' => [@admin.id.to_s])
        user.id.should_not be_nil
        # then add the domain
        user.update_attributes(:current_user => @adminuser, 'group_ids' => [@admin.id.to_s], "admin" => {"domain_ids" => [@main.id.to_s, @sub.id.to_s] })

        user.groups.member?(@admin).should be_true
        user.groups.size.should == 1

        user.domains_for_group(@admin).member?(@main).should be_true
        user.domains_for_group(@admin).size.should == 1
      end

      it 'should add only and delete domains' do
        # first create to have an ID
        user = User.create(:current_user => @adminuser, 'group_ids' => [@admin.id.to_s])
        user.id.should_not be_nil
        # then add the domain
        user.update_attributes(:current_user => @adminuser, 'group_ids' => [@admin.id.to_s], "admin" => {"domain_ids" => [@main.id.to_s, @sub.id.to_s] })

        user.groups.member?(@admin).should be_true
        user.groups.size.should == 1

        user.domains_for_group(@admin).member?(@main).should be_true
        user.domains_for_group(@admin).size.should == 1

        user.update_attributes(:current_user => @adminuser, 'group_ids' => [@admin.id.to_s], "admin" => {"domain_ids" => [] })
        user.domains_for_group(@admin).size.should == 0      
      end

      it 'should delete only domains belonging to the admin' do
        # first create to have an ID
        user = User.create(:current_user => @adminuser, 'group_ids' => [@admin.id.to_s])
        user.id.should_not be_nil
        # then add the domain
        user.update_attributes(:current_user => @superuser, 'group_ids' => [@admin.id.to_s], "admin" => {"domain_ids" => [@main.id.to_s, @sub.id.to_s] })

        user.groups.member?(@admin).should be_true
        user.groups.size.should == 1

        user.domains_for_group(@admin).member?(@main).should be_true
        user.domains_for_group(@admin).member?(@sub).should be_true
        user.domains_for_group(@admin).size.should == 2

        user.update_attributes(:current_user => @adminuser, 'group_ids' => [@admin.id.to_s], "admin" => {"domain_ids" => [] })

        user.domains_for_group(@admin).member?(@main).should be_false
        user.domains_for_group(@admin).member?(@sub).should be_true
        user.domains_for_group(@admin).size.should == 1      
      end
    end
  end
end


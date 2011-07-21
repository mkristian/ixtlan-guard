class UsersController < ApplicationController

#  ::Ixtlan::Models::GuardUser = User
#  ::Ixtlan::Models::GuardGroup = Group
#  ::Ixtlan::Models::GuardFlavorAssociations = [DomainsGroupsUser]

  cache_headers :protected, false
  before_filter :cache_headers

  private

  def intersection(set1, set2)
    set1 - (set1 - set2)
  end

  public

  # GET /users
  # GET /users.xml
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  def permissions
    render :xml => guard.permissions(self).to_xml
  end

  # GET /sessions/users/1/login
  def login
    @user = User.find(params[:id])
    session[:user] = @user

    respond_to do |format|
      format.html { 
        if allowed?(:index)
          redirect_to(users_url) 
        else
          #TODO translators
          redirect_to(courses_url(DomainsGroupsUser.all(:conditions => ["user_id=? and group_id=?", @user.id, @user.groups.first.id]).first.domain.name))
        end
      }
      format.xml  { head :ok }
    end
  end

  # GET /sessions/logout
  def logout
    session[:user] = nil
    
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

  # GET /sessions/maintanence
  def maintanance
    guard.block_groups([:teacher, :courses])
    
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

  # GET /sessions/resume
  def resume
    guard.block_groups([])
    
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to(@user, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])

    errors = []
    allowed_domain_ids = current_user.domains_for_group(Group.user)
    (params[:user][:group_ids] || []).each do |gid|
      g = Group.find(gid)
      domain_ids = @user.domains_for_group(gid.to_i).collect { |d| d.id }
      # calculate intersection of domains and allowed_domains
      existing_ids = intersection(domain_ids, allowed_domain_ids)

      target_ids = ((params[g.name] || {})[:domain_ids] || []).collect { |i| i.to_i }
      
      # delete 
      (existing_ids - target_ids).each do |id|
        DomainsGroupsUser.delete_all(:user_id => @user.id, :group_id => gid, :domain_id => id)
      end
      # add
      ids = target_ids - existing_ids
      intersection(ids, allowed_domain_ids).each do |id|
        DomainsGroupsUser.create(:user_id => @user.id, :group_id => gid, :domain_id => id)
      end
    end

     respond_to do |format|
      if @user.update_attributes(params[:user]) && errors.size == 0
        format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
end

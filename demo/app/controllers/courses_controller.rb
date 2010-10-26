class CoursesController < ApplicationController

  protected

  before_filter :locale_authorization

  skip_before_filter :authorization

  def locale_authorization
    @domain = Domain.find_by_name(params[:domain])
    authorization do |group| 
      if self.respond_to?(:current_user) && @domain
        user = self.send :current_user
        map = {
          "admin:courses" => ["asia", "europe"],
          "registrar:courses" => ["asia"],
          "teacher:teacher" => ["europe"]
        }
        allowed_domains = map[ user.name + ":" + group.to_s] || []
        allowed_domains.member?(@domain.name) || group == :root
      end
    end
  end

  public

  # GET /courses
  # GET /courses.xml
  def index
    @courses = Course.all(:conditions => ["domain_id = ?", @domain.id])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @courses }
    end
  end

  # GET /courses/1
  # GET /courses/1.xml
  def show
    @course = Course.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @course }
    end
  end

  # GET /courses/new
  # GET /courses/new.xml
  def new
    @course = Course.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @course }
    end
  end

  # GET /courses/1/edit
  def edit
    @course = Course.find(params[:id])
  end

  # POST /courses
  # POST /courses.xml
  def create
    @course = Course.new(params[:course])
    @course.domain = @domain

    respond_to do |format|
      if @course.save
        format.html { redirect_to(course_url(@domain.name, @course), :notice => 'Course was successfully created.') }
        format.xml  { render :xml => @course, :status => :created, :location => @course }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /courses/1
  # PUT /courses/1.xml
  def update
    @course = Course.find(params[:id])
    @course.domain = @domain

    respond_to do |format|
      if @course.update_attributes(params[:course])
        format.html { redirect_to(course_url(@domain.name, @course), :notice => 'Course was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /courses/1
  # DELETE /courses/1.xml
  def destroy
    @course = Course.find(params[:id])
    @course.destroy

    respond_to do |format|
      format.html { redirect_to(courses_url(@domain.name)) }
      format.xml  { head :ok }
    end
  end
end

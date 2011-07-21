require 'ixtlan/controllers/maintenance_controller'
class MaintenanceController < ApplicationController
  include ::Ixtlan::Controllers::MaintenanceController
end

  # ::Ixtlan::Models::Maintenance = Maintenance unless defined?(::Ixtlan::Models::Maintenance)

  # public

  # # GET /maintenance
  # # GET /maintenance.xml
  # # GET /maintenance.json
  # def index
  #   @maintenance = ::Ixtlan::Models::Maintenance.new
  #   @maintenance.groups = guard.blocked_groups

  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.xml  { render :xml => @maintenance }
  #     format.json  { render :json => @maintenance }
  #   end
  # end

  # # PUT /maintenance/block
  # def block
  #   guard.block_groups(param[:groups])
    
  #   respond_to do |format|
  #     format.html { redirect_to(maintenance_url) }
  #     format.xml  { head :ok }
  #   end
  # end

  # # PUT /maintenance/resume
  # def resume
  #   guard.block_groups([])
    
  #   respond_to do |format|
  #     format.html { redirect_to(maintenance_url) }
  #     format.xml  { head :ok }
  #   end
  # end
#end

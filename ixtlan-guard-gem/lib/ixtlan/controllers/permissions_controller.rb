module Ixtlan
  module Controllers
    module PermissionsController

      # GET /permissions
      # GET /permissions.xml
      # GET /permissions.json
      def index
        respond_to do |format|
          format.html
          format.xml  { render :xml => guard.permissions(self).to_xml }
          format.json  { render :json => guard.permissions(self).to_json }
        end
      end
      
      # GET /permissions/1
      # GET /permissions/1.xml
      # GET /permissions/1.json
      def show
        controller = Object.new
        def controller.current_user(u = nil)
          @u = u if u
          @u
        end
        controller.current_user(User.find(params[:id]))
        
        respond_to do |format|
          format.html
          format.xml  { render :xml => guard.permissions(controller).to_xml }
          format.json  { render :json => guard.permissions(controller).to_json }
        end
      end      
    end
  end
end

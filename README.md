# ixtlan guard #

* [![Build Status](https://secure.travis-ci.org/mkristian/ixtlan-guard.png)](http://travis-ci.org/mkristian/ixtlan-guard)
* [![Dependency Status](https://gemnasium.com/mkristian/ixtlan-guard.png)](https://gemnasium.com/mkristian/ixtlan-guard)
* [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/mkristian/ixtlan-guard)

it is an simple authorization framework for restful rails especially using rails as API server.

the idea is simple: 

* each user belongs to set of groups
* each controller/action pair permits a set of groups to execute it
* the guard class checks if the user has any group which is allowed by the controller/action pair

## current\_user\_groups method ##

this is similar to the **current_user** method common on authentication. the **current_user_groups** method is an array of object which responds to __:name__. call these objects groups which have name. the name is used in the permission config of the controller.

having something like PosixAccounts and PosixGroups (as know from ldap) would lead to an implementation like (which is the default when there is no such method)

     def current_user_groups
       current_user.groups
     end
     
## config for a controller

this is a yaml file in **RAILS_ROOT/app/guards/my\_users\_guard.yml**. for example

     my_users:
       index:
         - root
         - user-admin
         - app-admin
       show: [root,app-admin,guest]
       new: [root]
       create: [root]
       edit: [root,app-admin]
       update: [root,app-admin]
       destroy: [root]

with the special action **defaults** this can be reduced to

     my_users:
       defaults: [root]
       index:
         - root
         - user-admin
         - app-admin
       show: [root,app-admin,guest]
       edit: [root,app-admin]
       update: [root,app-admin]

and since **root** is handle by the guard anyways it can be further reduced to

     my_users:
       defaults: []
       index:
         - user-admin
         - app-admin
       show: [app-admin,guest]
       edit: [app-admin]
       update: [app-admin]

## rails helper methods

### authorize method of controller

  the authorize method asked the Guard if a certain action on a controller is allowed by the current_user, if not the method raises an Error. this method is registered as before-filter on the application-contrller. so **skip-before-filter :authorize** will disable the guard.
  
### allowed? method of controller

the call `allowed?(:destroy)` will give the permissions for the given action on the current controller.

### allowed? method of views

it takes two arguments since the controller name (or resource name) is needed as well. the call `allowed?(:users, :destroy)` will give the permissions for the given action controller pair.

### getting the Guard instance

to get an instance of the **Guard** on the controller itself just call `guard`. otherwise `Rails.application.config.guard` will give you such an instance.

# more advanced

sometimes you want to bind resource to a user/group pair, i.e. given an organizations which have report-writers and report-readers. example as rails before-filter:

    skip_before-filter :authorize
    guard_filter :authorize_organization_reader, :only => [:show]
    guard_filter :authorize_organization_writer, :only => [:edit, :update]

    def authorize_organization_writer(groups)
      groups.select { |g| g.writer?(current_user) }
    end
    
    def authorize_organization_reader
      groups.select { |g| g.writer?(current_user) || org.writer?(current_user)|}
    end

of course you can organize such relations also like that

    skip_before_filter :authorize
    guard_filter :authorize_organization

    def authorize_organization(groups)
      gou = GroupsOrganizationsUser.where(:org_id => params(:org_id),
                                          :user_id => current_user.id)
      ids = gou.collect { |i| i.group_id }
      groups.select { |g| ids.include?(g.id) }
    end

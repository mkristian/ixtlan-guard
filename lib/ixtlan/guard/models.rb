require 'virtus'
module Ixtlan
  module Guard
    class Action   
      include Virtus

      attribute :name, String
      attribute :associations, Array[String]
    end
    class Permission   
      include Virtus

      attribute :resource, String
      attribute :actions, Array[Action], :default => []
      attribute :deny, Boolean, :default => false
      attribute :associations, Array[String]
    end
    #TODO
    class GuardException < Exception; end
    class PermissionDenied < GuardException; end
  end
end

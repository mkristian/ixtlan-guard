module Ixtlan
  module Guard
    class AbstractSession

      attr_accessor :permissions, :user, :idle_session_timeout

      def self.create(login, password)
        self.do_create(authenticate(login, password))
      end
      
      def self.create_remote(login, password)
        self.do_create(authenticate_remote(login, password))
      end
      
      private

      def self.do_create(user)
        result = new
        
        if user.valid?
          result.user = user
        else
          result.log = user.to_log # error message
        end
        result
      end

      public

      def log=(msg)
        @log = msg
      end

      def to_log
        if @log
          @log
        else
          "Session(user-id: #{user.id}, idle-session-timeout: #{idle_session_timeout})"
        end
      end

      def valid?
        @log.nil?
      end
      
      def attributes
        {'idle_session_timeout' => idle_session_timeout, 'permissions' => permissions, 'user' => user}
      end
      
      protected

      def self.authenticate(login, password)
        raise "not implemented"
      end

      def self.authenticate_remote(login, password)
        raise "not implemented"
      end
    end
  end
end  

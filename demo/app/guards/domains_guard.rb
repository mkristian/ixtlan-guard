class DomainsGuard
  def initialize(guard)
    #guard.name = "domains"
    guard.aliases = {:new=>:create, :edit=>:update}
    guard.action_map= {
      :index => [],
      :show => [],
      :create => [],
      :update => [],
      :destroy => [],
    }
  end
end

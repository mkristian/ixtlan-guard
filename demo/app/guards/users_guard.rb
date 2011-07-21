class UsersGuard
  def initialize(guard)
    #guard.name = "users"
    guard.aliases = {:new=>:create, :edit=>:update}
    guard.action_map= {
      :index => [:users],
      :show => [:users],
      :create => [:users],
      :update => [:users],
      :destroy => [:users],
      :logout => [:*],
      :maintanance => [],
      :resume => [],
      :permissions => [:*]
    }
  end
end

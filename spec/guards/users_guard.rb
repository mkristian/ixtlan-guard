class UsersGuard
  def initialize(guard)
    guard.name = "users"
    guard.action_map= {
      :index => [:*],
      :show => [:users],
      :create => [:users],
      :update => [:users],
      :destroy => [:users]
    }
  end
end

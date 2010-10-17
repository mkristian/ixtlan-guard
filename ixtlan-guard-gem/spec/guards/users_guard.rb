class UsersGuard
  def initialize(guard)
    guard.name = "users"
    guard.aliases= {:edit => :update}
    guard.action_map= {
      :index => [:*],
      :show => [:users],
      :create => [:users],
      :update => [:users],
      :destroy => [:users]
    }
  end
end

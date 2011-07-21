class PermissionsGuard
  def initialize(guard)
    guard.action_map= {
      :index => [:*],
      :show => [:users]
    }
  end
end

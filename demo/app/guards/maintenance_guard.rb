class MaintenanceGuard
  def initialize(guard)
    guard.action_map= {
      :index => [],
      :block => [],
      :resume => []
    }
  end
end

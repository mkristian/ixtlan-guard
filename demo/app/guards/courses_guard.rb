class CoursesGuard
  def initialize(guard)
    #guard.name = "courses"
    guard.aliases = {:new=>:create, :edit=>:update}
    guard.action_map= {
      :index => [:courses, :teacher],
      :show => [:courses, :teacher],
      :create => [:courses],
      :update => [:courses],
      :destroy => [:courses],
    }
  end
end

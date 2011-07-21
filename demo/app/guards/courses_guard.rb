class CoursesGuard
  def initialize(guard)
    #guard.name = "courses"
    guard.flavor = :domain
    guard.aliases = {:new=>:create, :edit=>:update}
    guard.action_map= {
      :index => [:courses, :teachers],
      :show => [:courses, :teachers],
      :create => [:courses],
      :update => [:courses],
      :destroy => [:courses],
    }
  end
end

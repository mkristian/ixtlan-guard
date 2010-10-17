class User < ActiveRecord::Base

  def groups
    map = { 
      "root" => [:root], 
      "admin" => [:users, :courses], 
      "registrar" => [:courses] , 
      "teacher" => [:teacher] 
    }
    map[name] || []
  end
end

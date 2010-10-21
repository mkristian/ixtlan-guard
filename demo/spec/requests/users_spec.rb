require 'spec_helper'

def get_with_error(path)
  expect {
    get path
  }.to raise_error    
end

describe "Users" do
  describe "GET /users" do
    it "works! (now write some real specs)" do
      get users_path
      get login_user_path("2")
      get_with_error login_user_path("1")
      get logout_user_path("2")
    end
  end
end

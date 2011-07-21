Feature: Generators for ixtlan-guard

  Scenario: The guard generator creates a guard file for each controller
    Given I create new rails application with template "simple.template" and "simple" tests
    And I execute "rails generate controller users promote go"
    And I execute "rails generate scaffold account name:string --skip"
    And I execute "rake db:migrate test"
    Then the output should contain "7 tests, 10 assertions, 0 failures, 0 errors"

  Scenario: The user-management-model generator creates user/group models, etc
    Given I create new rails application with template "user_management.template" and "user-management" specs
    And I execute "rails generate rspec:install"
    And I execute "rails generate ixtlan:user_management_models user group name:string domain name:string locale code:string"
# this tes env is needed since we execute the specs directly
    And I execute "rails rake db:migrate -- -Drails.env=test"
# needed due to bug in rspec-maven-plugin with emtpy gem-path
    And I execute "gem exec ../rubygems/bin/rspec spec/user_management_models_spec.rb"
    Then the output should contain "14 examples, 0 failures"

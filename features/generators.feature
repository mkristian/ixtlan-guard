Feature: Generators for ixtlan-guard

  Scenario: The guard generator creates a guard file for each controller
    Given I create new rails application with template "simple.template" and "simple" tests
    And I execute "rails generate controller users promote go"
    And I execute "rails generate scaffold account name:string --skip"
    And I execute "rake db:migrate test"
    Then the output should contain "7 tests, 10 assertions, 0 failures, 0 errors"

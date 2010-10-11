Feature: Guard your controller actions.

  Scenario: The guard generators create a guard file for each controller
    Given I create new rails application with template "simple.template"
    Then the output should contain "7 tests, 10 assertions, 0 failures, 0 errors"

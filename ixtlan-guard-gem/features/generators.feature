Feature: Generators for ixtlan-guard

  Scenario: The guard generator creates a guard file for each controller
    Given I create new rails application with template "simple.template"
    Then the output should contain "7 tests, 10 assertions, 0 failures, 0 errors"

  Scenario: The user-management-model generator creates user/group models, etc
    Given I create new rails application with template "user_management.template"
    Then the output should contain "14 examples, 0 failures"

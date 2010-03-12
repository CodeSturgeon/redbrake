Feature: Should be able to model Source from Handbrake scan
  As a user
  I should be able to get a model of the Source
  So that I can interact with it
  Scenario: Restructure scan results
    When I restructure a scan result
    Then the output should be parsable as YAML
  Scenario: Make a Source model
    Given a YAML scan result
    Then I should be able to create a source

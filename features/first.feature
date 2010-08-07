Feature: First page
  Scenario: Title on first page
    Given I am on the home page
    Then I should see "Ruby Ores"

  Scenario: Can add link
    Given I am on the home page
    When I follow "Add link"
	And I fill in "title" with "Rubylinks"
    And I fill in "url" with "http://rubylink.com/post/1"
    And I press "Submit"
    Then I should be on the home page
    And I should see "Rubylinks"


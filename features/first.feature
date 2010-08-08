Feature: First page	
  Scenario: Title on first page
    Given I am on the home page
    Then I should see "Ruby Ores"
	
  Scenario Outline: Can add link
    Given I am on the home page
    When I follow "Add link"
	And I fill in "title" with "<title>"
    And I fill in "url" with "<url>"
	And I fill in "body" with "<body>"
    And I press "Submit"
    Then I should be on the home page
	And I should see a link with url "<output_url>"
    And I should see "<output>"
	
  Examples:
    | title | url                               | body           | output | output_url                    |
	| a    | http://www.google.com  | to be added | a        | http://www.google.com |
	| b    | www.yahoo.com          | to be added | b        | http://www.yahoo.com  |
	
	
  @clean
  Scenario: Use vote up
	Given I am on the home page
	When I press "vote_up"
	Then I should see "1"
	When I press "vote_down"
	Then I should see "0"
	

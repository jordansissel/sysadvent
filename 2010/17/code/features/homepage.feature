Feature: Homepage
  So we can keep existing users happy
  Visitors to the site
  Should be able to login

  Scenario: Check login box appears when login button is clicked
    Given I'm on the homepage
    When I click the login button
    Then I should see the login box


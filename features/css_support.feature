Feature: CSS support

  Scenario: Splitting single-line style definitions
    Given Vim is running
    And the splitjoin plugin is loaded
    And I'm editing a file named "example.css" with the following contents:
      """
      h2 { font-size: 18px; font-weight: bold }
      """
    And the cursor is positioned on "h2"
    And "expandtab" is set
    And "shiftwidth" is set to "2"
    When I split the line
    And I save
    Then the file "example.css" should contain the following text:
      """
      h2 {
        font-size: 18px;
        font-weight: bold;
      }
      """

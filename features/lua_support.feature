Feature: Lua support

  Scenario: Splitting single-line lambda functions
    Given Vim is running
    And the splitjoin plugin is loaded
    And I'm editing a file named "example.lua" with the following contents:
      """
      function () print("foo") end
      """
    And the cursor is positioned on "function"
    And "expandtab" is set
    And "shiftwidth" is set to "2"
    When I split the line
    And I save
    Then the file "example.lua" should contain the following text:
      """
      function ()
        print("foo")
      end
      """

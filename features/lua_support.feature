Feature: Lua support
  Background:
    Given Vim is running
    And the splitjoin plugin is loaded
    And "expandtab" is set
    And "shiftwidth" is set to "2"

  Scenario: Splitting lambda functions
    Given I'm editing a file named "example.lua" with the following contents:
      """
      local something = other(function (one, two) print("foo") end)
      """
    And the cursor is positioned on "function"
    When I split the line
    And I save
    Then the file "example.lua" should contain the following text:
      """
      local something = other(function (one, two)
        print("foo")
      end)
      """

  Scenario: Joining lambda functions
    Given I'm editing a file named "example.lua" with the following contents:
      """
      local something = other(function (one, two)
        print("foo")
      end)
      """
    And the cursor is positioned on "something"
    When I join the line
    And I save
    Then the file "example.lua" should contain the following text:
      """
      local something = other(function (one, two) print("foo") end)
      """

  Scenario: Splitting named functions
    Given I'm editing a file named "example.lua" with the following contents:
      """
      function example (one, two) print("foo") end
      """
    And the cursor is positioned on "example"
    When I split the line
    And I save
    Then the file "example.lua" should contain the following text:
      """
      function example (one, two)
        print("foo")
      end
      """

  Scenario: Joining named functions
    Given I'm editing a file named "example.lua" with the following contents:
      """
      function example ()
        print("foo")
        print("bar")
      end
      """
    And the cursor is positioned on "example"
    When I join the line
    And I save
    Then the file "example.lua" should contain the following text:
      """
      function example () print("foo"); print("bar") end
      """

  Scenario: Splitting empty functions
    Given I'm editing a file named "example.lua" with the following contents:
      """
      function example (one, two) end
      """
    And the cursor is positioned on "function"
    When I split the line
    And I save
    Then the file "example.lua" should contain the following text:
      """
      function example (one, two)
      end
      """

  Scenario: Joining empty functions
    Given I'm editing a file named "example.lua" with the following contents:
      """
      function example ()
      end
      """
    And the cursor is positioned on "function"
    When I join the line
    And I save
    Then the file "example.lua" should contain the following text:
      """
      function example () end
      """

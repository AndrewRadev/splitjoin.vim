[![Build Status](https://secure.travis-ci.org/AndrewRadev/splitjoin.vim.png?branch=master)](http://travis-ci.org/AndrewRadev/splitjoin.vim)

## Usage

This plugin is meant to simplify a task I've found too common in my workflow: switching between a single-line statement and a multi-line one. It offers the following default keybindings, which can be customized:

* `gS` to split a one-liner into multiple lines
* `gJ` (with the cursor on the first line of a block) to join a block into a single-line statement.

![Demo](http://i.andrewradev.com/df1c7b895602352d7ce3122196c3e6df.gif)

I usually work with ruby and a lot of expressions can be written very concisely on a single line. A good example is the "if" statement:

``` ruby
puts "foo" if bar?
```

This is a great feature of the language, but when you need to add more
statements to the body of the "if", you need to rewrite it:

``` ruby
if bar?
  puts "foo"
  puts "baz"
end
```

The idea of this plugin is to introduce a single key binding (default: `gS`) for transforming a
line like this:

``` html
<div id="foo">bar</div>
```

Into this:

``` html
<div id="foo">
  bar
</div>
```

And another binding (default: `gJ`) for the opposite transformation.

This currently works for:
  * Various constructs in Ruby and Eruby
  * Various constructs in Coffeescript
  * Various constructs in Perl
  * Various constructs in Python
  * Various constructs in Rust
  * PHP arrays
  * Javascript object literals and functions
  * Tags in HTML/XML
  * Handlebars components
  * CSS, SCSS, LESS style declarations.
  * YAML arrays and maps
  * Lua functions and tables
  * Go structs
  * Vimscript line continuations
  * TeX blocks
  * C if clauses and function calls
  * Do-blocks in Elixir

For more information, including examples for all of those languages, try `:help
splitjoin`, or take a look at the help file online at
[doc/splitjoin.txt](https://github.com/AndrewRadev/splitjoin.vim/blob/master/doc/splitjoin.txt)

## Contributing

If you'd like to hack on the plugin, please see
[CONTRIBUTING.md](https://github.com/AndrewRadev/splitjoin.vim/blob/master/CONTRIBUTING.md) first.

## Issues

Any issues and suggestions are very welcome on the
[github bugtracker](https://github.com/AndrewRadev/splitjoin.vim/issues).

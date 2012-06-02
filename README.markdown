[![Build Status](https://secure.travis-ci.org/AndrewRadev/splitjoin.vim.png?branch=master)](http://travis-ci.org/AndrewRadev/splitjoin.vim)

This plugin is meant to simplify a task I've found too common in my workflow:
switching between a single-line statement and a multi-line one.

I usually work with ruby and a lot of expressions can be written very concisely
on a single line. A good example is the "if" statement:

    puts "foo" if bar?

This is a great feature of the language, but when you need to add more
statements to the body of the "if", you need to rewrite it:

    if bar?
      puts "foo"
      puts "baz"
    end

The idea of this plugin is to introduce a single key binding for transforming a
line like this:

    <div id="foo">bar</div>

Into this:

    <div id="foo">
      bar
    </div>

And another binding for the opposite transformation. This currently works for
various constructs in ruby and erb, and for tags in html/xml.

For more information, try `:help splitjoin`, or take a look at the help file
online at
[doc/splitjoin.txt](https://github.com/AndrewRadev/splitjoin.vim/blob/master/doc/splitjoin.txt)

For more examples and corner cases, you can explore the "examples" directory
here:
[examples](https://github.com/AndrewRadev/splitjoin.vim/tree/master/examples).
It's not present in the downloadable zip file to avoid cluttering your vimfiles
with useless stuff.

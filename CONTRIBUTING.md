# Contributing

If you'd like to contribute to the project, you can use the usual github pull-request flow:

1. Fork the project
2. Make your change/addition, preferably in a separate branch.
3. Test the new behaviour and make sure all existing tests pass (optional, see below for more information).
4. Issue a pull request with a description of your feature/bugfix.

## Testing

This project uses [rspec](http://rspec.info/) and [vimrunner](https://github.com/AndrewRadev/vimrunner) to test its behaviour. Testing vimscript this way is still fairly experimental, but does a great job of catching regressions. Tests are written in the ruby programming language, so if you're familiar with it, you should (I hope) find the tests fairly understandable and easy to get into.

If you're not familiar with ruby, please don't worry about it :). I'd definitely appreciate it if you could take a look at the tests and attempt to write something that describes your change. Even if you don't, Travis-bot should run the tests upon issuing a pull request, so we'll know right away if there's a regression. In that case, I'll work on the tests myself and see what I can do.

To run the test suite, provided you have ruby installed, first you need bundler:

```
$ gem install bundler
```

If you already have the `bundle` command (check it out with `which bundle`), you don't need this step. Afterwards, it should be as simple as:

```
$ bundle install
$ bundle exec rspec spec
```

Depending on what kind of Vim you have installed, this may spawn a GUI Vim instance, or even several. You can read up on [vimrunner's README](https://github.com/AndrewRadev/vimrunner/blob/master/README.md) to understand how that works.

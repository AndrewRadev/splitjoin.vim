require 'spec_helper'

describe "rust" do
  let(:filename) { 'test.rs' }

  specify "match clauses with trailing comma" do
    set_file_contents <<~EOF
      match one {
          Ok(two) => some_expression(three),
      }
    EOF

    vim.search('Ok')
    split

    assert_file_contents <<~EOF
      match one {
          Ok(two) => {
              some_expression(three)
          },
      }
    EOF

    join

    assert_file_contents <<~EOF
      match one {
          Ok(two) => some_expression(three),
      }
    EOF
  end

  specify "match clauses without trailing comma" do
    set_file_contents <<~EOF
      match one {
          Ok(two) => some_expression(three)
      }
    EOF

    vim.search('Ok')
    split

    assert_file_contents <<~EOF
      match one {
          Ok(two) => {
              some_expression(three)
          },
      }
    EOF

    join

    assert_file_contents <<~EOF
      match one {
          Ok(two) => some_expression(three),
      }
    EOF
  end

  specify "question mark operator for io::Result" do
    set_file_contents <<~EOF
      fn test() -> io::Result {
          let file = File::open("foo.txt")?;
      }
    EOF

    vim.search('File')
    split

    assert_file_contents <<~EOF
      fn test() -> io::Result {
          let file = match File::open("foo.txt") {
              Ok(value) => value,
              Err(e) => return Err(e.into()),
          };
      }
    EOF

    vim.search('File')
    join

    assert_file_contents <<~EOF
      fn test() -> io::Result {
          let file = File::open("foo.txt")?;
      }
    EOF
  end

  specify "question mark operator for Option" do
    set_file_contents <<~EOF
      fn test() -> Option<T> {
          let thing = Some(3)?;
      }
    EOF

    vim.search('Some')
    split

    assert_file_contents <<~EOF
      fn test() -> Option<T> {
          let thing = match Some(3) {
              None => return None,
              Some(value) => value,
          };
      }
    EOF

    vim.search('Some')
    join

    assert_file_contents <<~EOF
      fn test() -> Option<T> {
          let thing = Some(3)?;
      }
    EOF
  end

  specify "question mark operator for an unknown return type" do
    set_file_contents <<~EOF
      let file = File::open("foo.txt")?;
    EOF

    vim.search('File')
    split

    assert_file_contents <<~EOF
      let file = match File::open("foo.txt") {
          Ok(value) => value,
          Err(e) => return Err(e.into()),
      };
    EOF

    vim.search('File')
    join

    assert_file_contents <<~EOF
      let file = File::open("foo.txt").unwrap();
    EOF
  end

  specify "complicated question mark operator" do
    set_file_contents <<~EOF
      fn complicated() -> Result {
          let bar = foo + match write!("{}", floof) {
              Ok(frob) => frob,
              Err(err) => return Err(err),
          } + 13;
      }
    EOF

    vim.search('match')
    join

    assert_file_contents <<~EOF
      fn complicated() -> Result {
          let bar = foo + write!("{}", floof)? + 13;
      }
    EOF

    vim.search('write')
    split

    assert_file_contents <<~EOF
      fn complicated() -> Result {
          let bar = foo + match write!("{}", floof) {
              Ok(value) => value,
              Err(e) => return Err(e.into()),
          } + 13;
      }
    EOF
  end

  specify "chained question mark operator" do
    set_file_contents <<~EOF
      fn foo() -> Result {
          let value = self.stack.pop().ok_or(Error::StackUnderflow)?;
      }
    EOF

    vim.search('ok_or')
    split

    assert_file_contents <<~EOF
      fn foo() -> Result {
          let value = match self.stack.pop().ok_or(Error::StackUnderflow) {
              Ok(value) => value,
              Err(e) => return Err(e.into()),
          };
      }
    EOF

    join

    assert_file_contents <<~EOF
      fn foo() -> Result {
          let value = self.stack.pop().ok_or(Error::StackUnderflow)?;
      }
    EOF
  end

  specify "closures in function calls" do
    set_file_contents <<~EOF
      let foo = something.map(|x| x * 2);
    EOF

    vim.search('|x|')
    split

    assert_file_contents <<~EOF
      let foo = something.map(|x| {
          x * 2
      });
    EOF

    join

    assert_file_contents <<~EOF
      let foo = something.map(|x| x * 2);
    EOF
  end

  specify "closures in assignment" do
    set_file_contents <<~EOF
      let foo = |x| x + 1;
    EOF

    vim.search('|x|')
    split

    assert_file_contents <<~EOF
      let foo = |x| {
          x + 1
      };
    EOF

    join

    assert_file_contents <<~EOF
      let foo = |x| x + 1;
    EOF
  end

  specify "complicated closures" do
    set_file_contents <<~EOF
      let foo = something.map(|x| mul(x, 2), y);
    EOF

    vim.search('|x|')
    split

    assert_file_contents <<~EOF
      let foo = something.map(|x| {
          mul(x, 2)
      }, y);
    EOF

    join

    assert_file_contents <<~EOF
      let foo = something.map(|x| mul(x, 2), y);
    EOF
  end

  specify "splitting closures with comparison operators" do
    set_file_contents <<~EOF
      do_stuff.where(|x| x < 5 && x > 3);
    EOF

    vim.search('|x|')
    split

    assert_file_contents <<~EOF
      do_stuff.where(|x| {
          x < 5 && x > 3
      });
    EOF
  end

  specify "closures with multiple lines" do
    set_file_contents <<~EOF
      let closure = |x| {
        print!("test");
        x + 1
      };
    EOF

    vim.search('|x|')
    join

    assert_file_contents <<~EOF
      let closure = |x| { print!("test"); x + 1 };
    EOF

    vim.search('{')
    split

    assert_file_contents <<~EOF
      let closure = |x| {
          print!("test");
          x + 1
      };
    EOF
  end

  specify "structs" do
    set_file_contents <<~EOF
      SomeStruct { foo: bar, bar: baz }
    EOF

    vim.search('foo')
    split

    assert_file_contents <<~EOF
      SomeStruct {
          foo: bar,
          bar: baz
      }
    EOF

    join

    assert_file_contents <<~EOF
      SomeStruct { foo: bar, bar: baz }
    EOF
  end

  specify "structs (trailing comma)" do
    set_file_contents <<~EOF
      SomeStruct { foo: bar, bar: baz }
    EOF

    vim.command('let b:splitjoin_trailing_comma = 1')
    vim.search('foo')
    split

    assert_file_contents <<~EOF
      SomeStruct {
          foo: bar,
          bar: baz,
      }
    EOF

    join

    assert_file_contents <<~EOF
      SomeStruct { foo: bar, bar: baz }
    EOF
  end

  specify "structs with shorthand definitions" do
    set_file_contents <<~EOF
      SomeStruct { foo, bar: baz }
    EOF

    vim.search('foo')
    split

    assert_file_contents <<~EOF
      SomeStruct {
          foo,
          bar: baz
      }
    EOF

    join

    assert_file_contents <<~EOF
      SomeStruct { foo, bar: baz }
    EOF
  end

  specify "structs with only shorthand definitions" do
    set_file_contents <<~EOF
      SomeStruct { foo, bar }
    EOF

    vim.search('foo')
    split

    assert_file_contents <<~EOF
      SomeStruct {
          foo,
          bar
      }
    EOF

    join

    assert_file_contents <<~EOF
      SomeStruct { foo, bar }
    EOF
  end

  specify "structs with defaults" do
    set_file_contents <<~EOF
      SomeStruct { foo, bar, ..Default::default() }
    EOF

    # No trailing comma on the default regardless of setting:
    vim.command('let b:splitjoin_trailing_comma = 1')

    vim.search('foo')
    split

    assert_file_contents <<~EOF
      SomeStruct {
          foo,
          bar,
          ..Default::default()
      }
    EOF

    join

    assert_file_contents <<~EOF
      SomeStruct { foo, bar, ..Default::default() }
    EOF
  end

  specify "structs with item attributes" do
    set_file_contents <<~EOF
      SomeStruct { foo, #[arg] #[cfg(test)] bar: "baz" }
    EOF

    vim.search('foo')
    split

    assert_file_contents <<~EOF
      SomeStruct {
          foo,
          #[arg]
          #[cfg(test)]
          bar: "baz"
      }
    EOF

    join

    assert_file_contents <<~EOF
      SomeStruct { foo, #[arg] #[cfg(test)] bar: "baz" }
    EOF
  end

  specify "structs with visibility modifiers" do
    set_file_contents <<~EOF
      SomeStruct { foo, pub bar: "baz", pub(crate) baz }
    EOF

    vim.search('foo')
    split

    assert_file_contents <<~EOF
      SomeStruct {
          foo,
          pub bar: "baz",
          pub(crate) baz
      }
    EOF

    join

    assert_file_contents <<~EOF
      SomeStruct { foo, pub bar: "baz", pub(crate) baz }
    EOF
  end

  specify "blocks" do
    set_file_contents <<~EOF
      if opt.verbose == 1 { foo(); do_thing(); bar() }
    EOF

    # this should not break the split:
    vim.command('let b:splitjoin_trailing_comma = 1')

    vim.search('foo')
    split

    assert_file_contents <<~EOF
      if opt.verbose == 1 {
          foo();
          do_thing();
          bar()
      }
    EOF

    join

    assert_file_contents <<~EOF
      if opt.verbose == 1 { foo(); do_thing(); bar() }
    EOF
  end

  specify "blocks with the cursor on an if-clause" do
    set_file_contents <<~EOF
      if opt.verbose == 1 { foo(); do_thing(); bar() }
    EOF

    vim.search('if')
    split

    assert_file_contents <<~EOF
      if opt.verbose == 1 {
          foo();
          do_thing();
          bar()
      }
    EOF

    join

    assert_file_contents <<~EOF
      if opt.verbose == 1 { foo(); do_thing(); bar() }
    EOF
  end

  specify "blocks (ending in semicolon)" do
    set_file_contents <<~EOF
      if opt.verbose == 1 { foo(); }
    EOF

    # this should not break the split:
    vim.command('let b:splitjoin_trailing_comma = 1')

    vim.search('foo')
    split

    assert_file_contents <<~EOF
      if opt.verbose == 1 {
          foo();
      }
    EOF

    join

    assert_file_contents <<~EOF
      if opt.verbose == 1 { foo(); }
    EOF
  end

  specify "unwrap match split" do
    set_file_contents <<~EOF
      let foo = other::expr() + File::open('test.file').unwrap();
    EOF

    vim.search('unwrap')
    split

    assert_file_contents <<~EOF
      let foo = other::expr() + match File::open('test.file') {

      };
    EOF
  end

  specify "expect match split" do
    set_file_contents <<~EOF
      let foo = other::expr() + File::open('test.file').expect("Missing file!");
    EOF

    vim.search('expect')
    split

    assert_file_contents <<~EOF
      let foo = other::expr() + match File::open('test.file') {

      };
    EOF
  end

  specify "struct with nested lambda (with curly brackets)" do
    set_file_contents <<~EOF
      Operation { input, callback: |x, y| { x + y } }
    EOF

    vim.search('input')
    split

    assert_file_contents <<~EOF
      Operation {
          input,
          callback: |x, y| { x + y }
      }
    EOF
  end

  specify "struct with nested lambda (without curly brackets)" do
    set_file_contents <<~EOF
      Operation { input, callback: |x, y| x + y }
    EOF

    vim.search('input')
    split

    assert_file_contents <<~EOF
      Operation {
          input,
          callback: |x, y| x + y
      }
    EOF
  end

  specify "struct with comma in character" do
    set_file_contents <<~EOF
      Operation { input, thing: ',', test }
    EOF

    vim.search('input')
    split

    assert_file_contents <<~EOF
      Operation {
          input,
          thing: ',',
          test
      }
    EOF
  end

  specify "struct with lifetime" do
    set_file_contents <<~EOF
      Operation { input, thing: Test<'a>, test }
    EOF

    vim.search('input')
    split

    assert_file_contents <<~EOF
      Operation {
          input,
          thing: Test<'a>,
          test
      }
    EOF
  end

  describe "imports" do
    specify "with cursor in curly brackets" do
      set_file_contents <<~EOF
        use std::io::{Read as R, foo::{Bar, Baz}, Write};
      EOF

      vim.search('Read as R')
      split

      assert_file_contents <<~EOF
        use std::io::{
            Read as R,
            foo::{Bar, Baz},
            Write
        };
      EOF

      vim.search('io::{')
      join

      assert_file_contents <<~EOF
        use std::io::{Read as R, foo::{Bar, Baz}, Write};
      EOF
    end

    specify "with cursor outside curly brackets" do
      set_file_contents <<~EOF
        use std::io::{Read, foo::{Bar, Baz}, Write};
      EOF

      vim.search('io::')
      split

      assert_file_contents <<~EOF
        use std::io::Read;
        use std::io::foo::{Bar, Baz};
        use std::io::Write;
      EOF

      vim.search('io::Read')
      join

      assert_file_contents <<~EOF
        use std::io::{Read, foo::{Bar, Baz}, Write};
      EOF
    end

    specify "aliases" do
      set_file_contents <<~EOF
        use std::io::{Read as R, Write as W};
      EOF

      vim.search('io::')
      split

      assert_file_contents <<~EOF
        use std::io::Read as R;
        use std::io::Write as W;
      EOF

      vim.search('io::Read')
      join

      assert_file_contents <<~EOF
        use std::io::{Read as R, Write as W};
      EOF
    end

    specify "join until next best match" do
      set_file_contents <<~EOF
        use std::io::Read;
        use std::fs::File;
        use std::io::Write;
      EOF

      vim.search('io::Read')
      join

      assert_file_contents <<~EOF
        use std::{io::Read, fs::File, io::Write};
      EOF

      set_file_contents <<~EOF
        use std::io::Read;
        use std::io::Write;
        use std::fs::File;
      EOF

      vim.search('io::Read')
      join

      assert_file_contents <<~EOF
        use std::io::{Read, Write};
        use std::fs::File;
      EOF
    end

    specify "merges curly brackets, doing some deduplication" do
      set_file_contents <<~EOF
        use std::io::{Read, Write};
        use std::io::{Write, Process, Read};
      EOF

      vim.search('io::{Read')
      join

      assert_file_contents <<~EOF
        use std::io::{Read, Write, Process, Read};
      EOF
    end

    specify "deletes duplicate lines" do
      set_file_contents <<~EOF
        use std::io::Read;
        use std::io::Read;
        use std::io::Write;
      EOF

      vim.search('io::Read')
      join

      assert_file_contents <<~EOF
        use std::io::Read;
        use std::io::Write;
      EOF
    end

    specify 'correctly splits a `self` import' do
      set_file_contents 'use std::io::{self, Write};'
      split

      assert_file_contents <<~EOF
        use std::io;
        use std::io::Write;
      EOF

      set_file_contents 'use std::io::{Read, self, Write};'
      split

      assert_file_contents <<~EOF
        use std::io::Read;
        use std::io;
        use std::io::Write;
      EOF
    end

    specify 'correctly joins a `self` import' do
      # As the first arg
      set_file_contents <<~EOF
        use std::io;
        use std::io::Read;
        use std::io::Write;
      EOF
      vim.normal('gg')
      join
      assert_file_contents 'use std::io::{self, Read, Write};'

      # As the second arg
      set_file_contents <<~EOF
        use std::io::Read;
        use std::io;
        use std::io::Write;
      EOF
      vim.normal('gg')
      join
      assert_file_contents 'use std::io::{Read, self, Write};'

      # After the second arg
      set_file_contents <<~EOF
        use std::io::Read;
        use std::io::Write;
        use std::io;
      EOF
      vim.normal('gg')
      join
      assert_file_contents 'use std::io::{Read, Write, self};'
    end
  end

  describe "if-let and match" do
    specify "basic if-let into match" do
      set_file_contents <<~EOF
        if let Some(value) = iterator.next() {
            println!("do something with {}", value);
        }
      EOF

      vim.search('let')
      split

      assert_file_contents <<~EOF
        match iterator.next() {
            Some(value) => {
                println!("do something with {}", value);
            },
            _ => (),
        }
      EOF
    end

    specify "if-let with else" do
      set_file_contents <<~EOF
        if let Some(value) = iterator.next() {
            Some("Okay")
        } else {
            None
        }
      EOF

      vim.search('let')
      split

      assert_file_contents <<~EOF
        match iterator.next() {
            Some(value) => Some("Okay"),
            _ => None,
        }
      EOF
    end

    specify "if-let with multi-line else" do
      set_file_contents <<~EOF
        if let Some(value) = iterator.next() {
            Some("Okay")
        } else {
            println!("None");
            None
        }
      EOF

      vim.search('let')
      split

      assert_file_contents <<~EOF
        match iterator.next() {
            Some(value) => Some("Okay"),
            _ => {
                println!("None");
                None
            },
        }
      EOF
    end

    specify "if-let with else with semicolon" do
      set_file_contents <<~EOF
        if let Some(value) = iterator.next() {
            println!("do something with {}", value);
        } else {
            println!("Nothing!");
        }
      EOF

      vim.search('let')
      split

      assert_file_contents <<~EOF
        match iterator.next() {
            Some(value) => {
                println!("do something with {}", value);
            },
            _ => {
                println!("Nothing!");
            },
        }
      EOF
    end

    specify "empty match with block into if-let" do
      set_file_contents <<~EOF
        match iterator.next() {
            Some(value) => {
                println!("do something with {}", value);
            },
            _ => (),
        }
      EOF

      vim.search('match')
      join

      assert_file_contents <<~EOF
        if let Some(value) = iterator.next() {
            println!("do something with {}", value);
        }
      EOF
    end

    specify "empty match on one line into if-let" do
      set_file_contents <<~EOF
        match iterator.next() {
            Some(value) => Some(value * 2),
            _ => (),
        }
      EOF

      vim.search('match')
      join

      assert_file_contents <<~EOF
        if let Some(value) = iterator.next() {
            Some(value * 2)
        }
      EOF
    end

    specify "match into if-let-else" do
      set_file_contents <<~EOF
        match iterator.next() {
            Some(value) => Some(value * 2),
            _ => None,
        }
      EOF

      vim.search('match')
      join

      assert_file_contents <<~EOF
        if let Some(value) = iterator.next() {
            Some(value * 2)
        } else {
            None
        }
      EOF
    end

    specify "match into multiline if-let-else" do
      set_file_contents <<~EOF
        match iterator.next() {
            Some(value) => {
                println!("if");
                Some(value * 2)
            },
            _ => {
                println!("if");
                None
            },
        }
      EOF

      vim.search('match')
      join

      assert_file_contents <<~EOF
        if let Some(value) = iterator.next() {
            println!("if");
            Some(value * 2)
        } else {
            println!("if");
            None
        }
      EOF
    end
  end
end

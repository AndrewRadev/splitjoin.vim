require 'spec_helper'

describe "rust" do
  let(:filename) { 'test.rs' }

  before :each do
    pending "Broken on TravisCI due to old Vim version" if ENV['TRAVIS_CI']
  end

  specify "match clauses" do
    set_file_contents <<-EOF
      match one {
          Ok(two) => some_expression(three),
      }
    EOF

    vim.search('Ok')
    split

    assert_file_contents <<-EOF
      match one {
          Ok(two) => {
              some_expression(three)
          },
      }
    EOF

    join

    assert_file_contents <<-EOF
      match one {
          Ok(two) => some_expression(three),
      }
    EOF
  end

  specify "question mark operator for Result" do
    set_file_contents <<-EOF
      fn test() -> io::Result {
          let file = File::open("foo.txt")?;
      }
    EOF

    vim.search('File')
    split

    assert_file_contents <<-EOF
      fn test() -> io::Result {
          let file = match File::open("foo.txt") {
              Ok(value) => value,
              Err(e) => return Err(e.into()),
          };
      }
    EOF

    vim.search('File')
    join

    assert_file_contents <<-EOF
      fn test() -> io::Result {
          let file = File::open("foo.txt")?;
      }
    EOF
  end

  specify "question mark operator for Option" do
    set_file_contents <<-EOF
      fn test() -> Option<T> {
          let thing = Some(3)?;
      }
    EOF

    vim.search('Some')
    split

    assert_file_contents <<-EOF
      fn test() -> Option<T> {
          let thing = match Some(3) {
              None => return None,
              Some(value) => value,
          };
      }
    EOF

    vim.search('Some')
    join

    assert_file_contents <<-EOF
      fn test() -> Option<T> {
          let thing = Some(3)?;
      }
    EOF
  end

  specify "question mark operator for Option" do
    set_file_contents <<-EOF
      let file = File::open("foo.txt")?;
    EOF

    vim.search('File')
    split

    assert_file_contents <<-EOF
      let file = match File::open("foo.txt") {
          Ok(value) => value,
          Err(e) => return Err(e.into()),
      };
    EOF

    vim.search('File')
    join

    assert_file_contents <<-EOF
      let file = File::open("foo.txt")?;
    EOF
  end

  specify "complicated question mark operator" do
    set_file_contents <<-EOF
      let bar = foo + match write!("{}", floof) {
          Ok(frob) => frob,
          Err(err) => return Err(err),
      } + 13;
    EOF

    vim.search('match')
    join

    assert_file_contents <<-EOF
      let bar = foo + write!("{}", floof)? + 13;
    EOF

    vim.search('write')
    split

    assert_file_contents <<-EOF
      let bar = foo + match write!("{}", floof) {
          Ok(value) => value,
          Err(e) => return Err(e.into()),
      } + 13;
    EOF
  end

  specify "closures" do
    set_file_contents <<-EOF
      let foo = something.map(|x| x * 2);
    EOF

    vim.search('|x|')
    split

    assert_file_contents <<-EOF
      let foo = something.map(|x| {
          x * 2
      });
    EOF

    join

    assert_file_contents <<-EOF
      let foo = something.map(|x| x * 2);
    EOF
  end

  specify "complicated closures" do
    set_file_contents <<-EOF
      let foo = something.map(|x| mul(x, 2), y);
    EOF

    vim.search('|x|')
    split

    assert_file_contents <<-EOF
      let foo = something.map(|x| {
          mul(x, 2)
      }, y);
    EOF

    join

    assert_file_contents <<-EOF
      let foo = something.map(|x| mul(x, 2), y);
    EOF
  end

  specify "structs" do
    set_file_contents <<-EOF
      SomeStruct { foo: bar, bar: baz }
    EOF

    vim.search('foo')
    split

    assert_file_contents <<-EOF
      SomeStruct {
          foo: bar,
          bar: baz
      }
    EOF

    join

    assert_file_contents <<-EOF
      SomeStruct { foo: bar, bar: baz }
    EOF
  end

  specify "structs (trailing comma)" do
    set_file_contents <<-EOF
      SomeStruct { foo: bar, bar: baz }
    EOF

    vim.command('let b:splitjoin_trailing_comma = 1')
    vim.search('foo')
    split

    assert_file_contents <<-EOF
      SomeStruct {
          foo: bar,
          bar: baz,
      }
    EOF

    join

    assert_file_contents <<-EOF
      SomeStruct { foo: bar, bar: baz }
    EOF
  end

  specify "fallback match split" do
    set_file_contents <<-EOF
      let foo = Some::value(chain).of(things);
    EOF

    vim.search('Some')
    split

    assert_file_contents <<-EOF
      let foo = match Some::value(chain).of(things) {

      };
    EOF
  end
end

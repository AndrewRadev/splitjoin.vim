require 'spec_helper'

describe "rust" do
  let(:filename) { 'test.rs' }

  specify "match clauses" do
    pending "Broken on TravisCI due to old Vim version" if ENV['TRAVIS_CI']

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

  specify "question mark operator" do
    pending "Broken on TravisCI due to old Vim version" if ENV['TRAVIS_CI']

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
    pending "Broken on TravisCI due to old Vim version" if ENV['TRAVIS_CI']

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

  specify "structs" do
    pending "Broken on TravisCI due to old Vim version" if ENV['TRAVIS_CI']

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
    pending "Broken on TravisCI due to old Vim version" if ENV['TRAVIS_CI']

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
end

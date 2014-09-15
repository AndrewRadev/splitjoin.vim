require 'spec_helper'

describe "php" do
  let(:filename) { 'test.php' }

  before(:each) do
    vim.set(:shiftwidth, 2)
  end

  specify "arrays" do
    set_file_contents '<?php $foo = array("one" => "two", "three" => "four"); ?>'

    split

    assert_file_contents <<-EOF
      <?php $foo = array(
        "one" => "two",
        "three" => "four"
      ); ?>
    EOF

    join

    assert_file_contents '<?php $foo = array("one" => "two", "three" => "four"); ?>'
  end

  specify "square-bracketed lists" do
    set_file_contents '<?php $foo = [1, 2, 3]; ?>'

    split

    assert_file_contents <<-EOF
      <?php $foo = [
        1,
        2,
        3
      ]; ?>
    EOF

    join

    assert_file_contents '<?php $foo = [1, 2, 3]; ?>'
  end

  specify "if-clauses" do
    set_file_contents <<-EOF
      <?php
      if ($foo) { $a = "bar"; }
      ?>
    EOF

    vim.search('if')
    split

    assert_file_contents <<-EOF
      <?php
      if ($foo) {
        $a = "bar";
      }
      ?>
    EOF

    join

    assert_file_contents <<-EOF
      <?php
      if ($foo) { $a = "bar"; }
      ?>
    EOF
  end

  specify "<?php markers" do
    set_file_contents "<?php example(); ?>"

    vim.search('example')
    split

    assert_file_contents <<-EOF
      <?php
      example();
      ?>
    EOF

    vim.search('php')
    join

    assert_file_contents "<?php example(); ?>"
  end

  specify "<?= markers" do
    set_file_contents "<?= 'example'; ?>"

    vim.search('example')
    split

    assert_file_contents <<-EOF
      <?=
      'example';
      ?>
    EOF

    vim.search('<?')
    join

    assert_file_contents "<?= 'example'; ?>"
  end

  specify "<? markers" do
    set_file_contents "<? example(); ?>"

    vim.search('example')
    split

    assert_file_contents <<-EOF
      <?
      example();
      ?>
    EOF

    vim.search('<?')
    join

    assert_file_contents "<? example(); ?>"
  end
end

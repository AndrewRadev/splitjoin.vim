<?php

$foo = array(
  'one'   => 'two',
  'three' => 'four'
);

$foo = [1, 2, 3];

if ($foo) {
  $a = 'bar';
}

?>

<div>
<?php echo "OK"; ?>

<? example(); ?>
<?= example(); ?>
</div>

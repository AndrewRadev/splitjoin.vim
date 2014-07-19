print "a = $a\n" if $debug;
print "OK" unless $error;

if ($debug) {
  print "a = $a\n";
  print "b = $b\n";
}

if ($debug) { print "foo"; }

if ($debug)
{
  print "a = $a\n";
}

open PID, ">", $pidfile or die;
print "something" and exit;

my $info = {name => $name, age => $age};
my @var = ['one', 'two', 'three'];
my @var = ('one', 'two', 'three');
my @var = qw(one two three);

print "a = $a\n" if $debug;
print "OK" unless $error;

if ($debug) {
  print "a = $a\n";
  print "b = $b\n";
}

if ($debug)
{
  print "a = $a\n";
}

open PID, ">", $pidfile or die;
print "something" and exit;

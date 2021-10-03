#!/usr/bin/perl

use Modern::Perl '2018';
use experimental 'signatures';
use Excel2CSV;
use Data::Dumper;
use FindBin qw($Bin);
use strict;
use warnings; no warnings  'experimental';
binmode(STDOUT, ":utf8");

our $Xls_ext   = '.xlsx';

sub main(@argv) {
  my $csv = "owners";
  chdir("$Bin/../tmp");
  print "Converting to XLS\n";
  csv2excel($csv);
}

# call main
main($0, @ARGV);

__END__

-----------------------------------------------------


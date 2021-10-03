#!/usr/bin/perl

use Modern::Perl '2018';
use experimental 'signatures';
use Excel2CSV;
use DBI;
use DBD::CSV;
use DBD::Pg;
use Data::Dumper;
use FindBin qw($Bin);
use File::Copy;
use Foo_Bar;
use strict;
use warnings; no warnings  'experimental';
binmode(STDOUT, ":utf8");

our $Host = 'mesh';
our $User = undef;
our $Pass = undef;
our $Csv_ext   = '.csv';
our $Xls_ext   = '.xlsx';
our $Xls_file  = $ENV{HOME} . '/Dropbox/Shared/Home/!Contacts & Roles' . $Xls_ext;

sub main(@argv) {
  ($User,$Pass) = foo("$Host:pg");
  my $csv = "owners";
  chdir("$Bin/../tmp");
  # Convert Excel to CSV
  if(
    (! -f ($csv . $Xls_ext))         or
    (! -f ($csv  . "1" . $Csv_ext) ) or    
    (-M $Xls_file < -M $csv . $Xls_ext)  
  ) {
    print "Converting to CSV\n";
    copy($Xls_file, $csv . $Xls_ext) || die("Cannot copy file '': $!");
    excel2csv($csv);
  }
  
  # Connect to dbs
  my $dbh1 = DBI->connect(
    "dbi:CSV:", undef, undef, {
      f_dir      => ".",
      f_ext      => ".csv/r",
      RaiseError => 1,
    }
  ) or die "Cannot connect: $DBI::errstr";
  my $dbh2 = DBI->connect(
    "dbi:Pg:dbname=mesh;host=$Host", $User, $Pass, {
      AutoCommit => 0,
      RaiseError => 1,
    }
  ) or die "Cannot connect: $DBI::errstr";
  
  # Do Queries
  my $owners = $dbh1->selectall_hashref("
    select *
    from ${csv}1;",
    "suite");
  my $fobs   = $dbh2->selectall_hashref("
    select distinct users.userid,users.firstname,carddata.carddata 
    from users,carddata 
    where users.userid = carddata.userid;",
    "userid");
  my $unused = $dbh2->selectall_hashref("
    select userid,carddata 
    from carddata 
    where carddata not in (
    select distinct cardnumber from logs 
    where cardnumber is not null);",
    "carddata");

  # Print output
  print "FOB    UNT  OWNER\n";
  for my $fobid (sort keys %$unused) {
    my $ownerid = $$unused{$fobid}{userid};
    my $suite = $$fobs{$ownerid}{firstname};
    my $owner = $$owners{$suite}{owner_list} || $suite;
    $suite = uc substr($suite,0,3);
    print "$fobid  $suite  $owner\n";
  }
  
  # Disconnect
  $dbh1->disconnect();
  $dbh2->disconnect();
}

# call main
main($0, @ARGV);

__END__

-----------------------------------------------------

cd ~/Dropbox/Shared/Home/Strata\ Documents/bin

./fob-log-query.pl | (read h; echo "$h"; sort +1)
echo "select logtime,cardnumber,result from logs where firstname = 'Garbage' order by logtime;"|meshdb|perl -lpe 's,\d:\d{2}\.\d+,0,;s,\s+, ,g'|sort|uniq
echo "select distinct date(logtime) from logs where firstname = 'Garbage' order by date(logtime);"|meshdb|perl -lne 's/^\s*\d{4}-//;/^(\d{2})-(\d{2})/ and push(@{$d{$1}} , $2);END{for $k (keys %d){print "==$k\n".join("\n",@{$d{$k}})}}'

-----------------------------------------------------

PGPASSWORD=xxx psql -h mesh -U xxx -d mesh

\h        HELP
\l        LIST DATABSES
\c mesh   CONNECT TO DATABSE
\dt       DUMP TABLES
\d+ table DUMP COLUMNS of table
\q        QUIT


41 select distinct cardnumber from logs where cardnumber is not null order by cardnumber;
65 select carddata from carddata order by carddata;
40 select carddata from carddata where carddata     in (select distinct cardnumber from logs where cardnumber is not null);
25 select carddata from carddata where carddata not in (select distinct cardnumber from logs where cardnumber is not null);

42 [SUITES + Garbage + Viscount]
44 select firstname from users order by firstname;
44 select users.firstname,count(carddata.carddata) as fobs from users,carddata
     where users.userid = carddata.userid 
     group by users.firstname
     order by users.firstname;
 8 select firstname,lastaccess from users where (lastaccess is null OR lastaccess < now() - '6 months' :: interval) order by firstname;
65 select distinct users.firstname,carddata.carddata from users,carddata where users.userid = carddata.userid order by users.firstname;
25 select distinct users.firstname,carddata.carddata from users,carddata
     where (users.userid = carddata.userid AND 
     carddata.carddata not in (select distinct cardnumber from logs where cardnumber is not null) )
     order by users.firstname;

10 select distinct date(logtime) from logs where firstname = 'Garbage' order by date(logtime);

 0 select distinct cardnumber,result from logs where (cardnumber is not null and result <> 'Granted') order by cardnumber;

-----------------------------------------------------

$dbh = DBI->connect ("dbi:CSV:", undef, undef, {
  f_schema        => undef,
  f_dir           => "data",    # this is a relative path
  f_dir_search    => [],
  f_ext           => ".csv/r",  # the "/r" means the ext is required (not optional)
  f_lock          => 2,
  f_encoding      => "utf8",
  csv_eol         => "\r\n",
  csv_sep_char    => ",",
  csv_quote_char  => '"',
  csv_escape_char => '"',
  csv_class       => "Text::CSV_XS",
  csv_null        => 1,
  csv_bom         => 0,
  csv_tables      => {
    syspwd => {
      sep_char    => ":",
      quote_char  => undef,
      escape_char => undef,
      file        => "/etc/passwd",
      col_names   => [qw(
        login password
        uid gid realname
        directory shell
      )],
    },
  },
  RaiseError       => 1,
  PrintError       => 1,
  FetchHashKeyName => "NAME_lc",
}) or die $DBI::errstr;


ID,INITIALS,NAME,COMMENT
0,CP,"Pollitt, Chris","Chris ""Laughingman"" Pollitt"
1,MH,"Houle, Michelle","Michelle ""Sneaky"" Houle"
2,JS,"Smith, John","John ""X"" Smith"

-----------------------------------------------------

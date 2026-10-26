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
use strict;
use warnings; no warnings  'experimental';
binmode(STDOUT, ":utf8");

our $Csv_ext   = '.csv';
our $Xls_ext   = '.xlsx';
our $Xls_file1  = $ENV{HOME} . '/OneDrive/!Shared/Strata/docs/Contacts & Roles' . $Xls_ext;
our $Xls_file2  = $ENV{HOME} . '/OneDrive/!Shared/Strata/docs/Key Log' . $Xls_ext;
our $Xls_file3  = $ENV{HOME} . '/OneDrive/!Shared/Strata/docs/Laundry Card List by Unit' . $Xls_ext;
our $Xls_file4  = $ENV{HOME} . '/OneDrive/!Shared/Strata/docs/Parking' . $Xls_ext;

sub main(@argv) {
  # csv files
  my $csv1 = "owners";
  my $csv2 = "keys";
  my $csv3 = "lcards";
  my $csv4 = "parking";
  chdir("$Bin/../docs/tmp");
  # Mapping of command-line arguments to the corresponding variables
  our($unit,$buzz,$owner, $phone,$fobl,$keyl,$lcardl,$parkingl,$match);
  my %fields = (
    'unit'    => sub { $unit     eq $match },
    'buzz'    => sub { $buzz     eq $match },
    'owner'   => sub { $owner    =~ /$match/i },
    'phone'   => sub { $phone    =~ /$match/i },
    'fob'     => sub { $fobl     =~ /\b$match\b/ },
    'key'     => sub { $keyl     =~ /\b$match\b/ },
    'laundry' => sub { $lcardl   =~ /\b$match\b/ },
    'parking' => sub { $parkingl =~ /\b$match\b/ },
   );
  # Convert Excel to CSV
  if(
    (! -f ($csv1 . $Xls_ext))         or
    (! -f ($csv1  . "1" . $Csv_ext) ) or    
    (-M $Xls_file1 < -M $csv1 . $Xls_ext)  
  ) {
    print "Converting $csv1 to CSV\n";
    copy($Xls_file1, $csv1 . $Xls_ext) || die("Cannot copy file '': $!");
    excel2csv($csv1);
  }
  if(
    (! -f ($csv2 . $Xls_ext))         or
    (! -f ($csv2  . "1" . $Csv_ext) ) or    
    (-M $Xls_file2 < -M $csv2 . $Xls_ext)  
  ) {
    print "Converting $csv2 to CSV\n";
    copy($Xls_file2, $csv2 . $Xls_ext) || die("Cannot copy file '': $!");
    excel2csv($csv2);
  }
  if(
    (! -f ($csv3 . $Xls_ext))         or
    (! -f ($csv3  . "1" . $Csv_ext) ) or    
    (-M $Xls_file3 < -M $csv3 . $Xls_ext)  
  ) {
    print "Converting $csv3 to CSV\n";
    copy($Xls_file3, $csv3 . $Xls_ext) || die("Cannot copy file '': $!");
    excel2csv($csv3);
  }
  if(
    (! -f ($csv4 . $Xls_ext))         or
    (! -f ($csv4  . "1" . $Csv_ext) ) or    
    (-M $Xls_file4 < -M $csv4 . $Xls_ext)  
  ) {
    print "Converting $csv4 to CSV\n";
    copy($Xls_file4, $csv4 . $Xls_ext) || die("Cannot copy file '': $!");
    excel2csv($csv4);
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
    "dbi:Pg:dbname=mesh;host=mesh", 'mesh', undef, {
      AutoCommit => 0,
      RaiseError => 1,
    }
  ) or die "Cannot connect: $DBI::errstr";
  
  # Do Queries
  my $owners = $dbh1->selectall_hashref("
    select *
    from ${csv1}1;",
    "suite");
  my $keys = $dbh1->selectall_hashref("
    select *
    from ${csv2}1;",
    "key");
  my $lcards = $dbh1->selectall_hashref("
    select *
    from ${csv3}1;",
    "unit");
  my $parkings = $dbh1->selectall_hashref("
    select *
    from ${csv4}1;",
    "unit");
  my $userids   = $dbh2->selectall_hashref("
    select distinct users.userid,users.firstname,carddata.carddata 
    from users,carddata 
    where users.userid = carddata.userid;",
    "userid");
  my $fobids = $dbh2->selectall_hashref("
    select userid,carddata 
    from carddata;",
    "carddata");
  # FOBS
  my %fobs;
  for my $fobid (sort {$a <=> $b} keys %$fobids) {
    my $ownerid = $$fobids{$fobid}{userid};
    my $suite = $$userids{$ownerid}{firstname};
    my $osuite = $suite;
    $suite = uc substr($suite,0,3);
    $$owners{$suite}{owner_list} = $osuite unless($$owners{$suite}{owner_list});
    $fobs{$suite} .= "$fobid,";
  }
  # KEYS
  my %keys;
  for my $keyid (sort {$a <=> $b} keys %$keys) {
		last if(!length($$keys{$keyid}{suite})); # bail if at end of assigned keys
    my $suite = $$keys{$keyid}{suite};
		my $osuite = $suite;
    $suite = uc substr($suite,0,3);
    $keys{$suite} .= "$keyid,";
    $$owners{$suite}{owner_list} = $osuite unless($$owners{$suite}{owner_list});
  }
  # Laundry CARDS
  my %lcards;
  for my $suite (sort {$a <=> $b} keys %$lcards) {
    $suite = uc substr($suite,0,3);
    my $lcard = 
      ($$lcards{$suite}{card_1} // "") . "," .
      ($$lcards{$suite}{card_2} // "") . "," .
      ($$lcards{$suite}{card_3} // "") . "," .
      ($$lcards{$suite}{card_4} // "");
    $lcards{$suite} .= "$lcard";
    $lcards{$suite} =~ s/,+$//g;
  }
  # Parking spots
  my %parkings;
  for my $suite (sort {$a cmp $b} keys %$parkings) {
		my $osuite = $suite;
    $suite = uc substr($suite,0,3);
    my $parking = 
      ($$parkings{$suite}{assignment} // "") . "," .
      ($$parkings{$suite}{rental}     // "");
    $parkings{$suite} .= "$parking";
    $parkings{$suite} =~ s/,+$//g;
		if($suite eq "BLD") {
			$$owners{$suite}{owner_list} = "Building";
		}
  }
  # Print output
  print "UNI BUZ OWNER PHONE FOBS KEYS LCARDS PARK\n";
  my %all_suites = map { $_ => 1 } (keys %fobs, keys %keys, keys %lcards, keys %parkings);
  for my $suite (sort {$a cmp $b} keys %all_suites) {	
     $unit  = $suite;
     $owner = ($$owners{$suite}{owner_list} // "");
     $buzz  = $$owners{$suite}{buzz} || "000";
     $phone = $$owners{$suite}{phone} || "000-000-0000";
     $phone =~ s/\(//g; $phone =~ s/\) ?/-/g;
     $fobl  = $fobs{$suite}   || "(none)";
     $keyl  = $keys{$suite}   || "(none)";
     $lcardl= $lcards{$suite} || "(none)";
     $parkingl= $parkings{$suite} || "(none)";
     $owner =~ s/^\s+|\s+$//g;
     $owner = qq/"$owner"/;
     $fobl  =~ s/,$//g;
     $keyl  =~ s/,$//g;
     $lcardl=~ s/,$//g;
     $parkingl=~ s/,$//g;
     if($argv[1]) {
       if(!$argv[2]) {
         print STDERR "Must supply value to match\n";
         last; #exit(1);
       }
       $match = $argv[2];
       # Check if the command-line argument is valid
       if (exists $fields{$argv[1]}) {
         # Execute the corresponding condition and print if true
         if ($fields{$argv[1]}->()) {
           print join(" ", $unit, $buzz, $owner, $phone, $fobl, $keyl, $lcardl, $parkingl) . "\n";
         }
       } else {
         # Generate the list of valid field names
         my $valid_fields = join(', ', sort keys %fields);    
         # Print error message with the valid field names
         print STDERR "Must use one of: $valid_fields\n";
         last; # or exit(1);
       }
     } else {
       print join(" ", $unit, $buzz, $owner, $phone, $fobl, $keyl, $lcardl, $parkingl) . "\n";
     }
  }
  
  # Disconnect
  $dbh1->disconnect();
  $dbh2->disconnect();
}

# call main
main($0, @ARGV);

__END__

"Owner List",Suite,"Enterphone Name",Buzz,Phone,Phone2,Email,Facebook,Year,NOTES

F 'buzz'            => 905
  'email'           => 'firstlast@gmail.com'
* 'enterphone_name' => 'Lastname'
  'facebook'        => 'firstlast'
  'notes'           => ''
  'owner_list'      => 'First Last'
* 'phone'           => '604-555-1212'
  'phone2'          => ''
F 'suite'           => 308
  'year'            => 2017

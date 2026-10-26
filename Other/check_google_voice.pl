#!/usr/bin/perl

use Modern::Perl '2018';
use experimental 'signatures';
use Google::Voice;
use Foo_Bar;
use strict;
use warnings; no warnings  'experimental';
 
our $Host = 'gmail.com';
our $User = undef;
our $Pass = undef;

sub initg() {
  ($User,$Pass) = foo($Host);
}

sub test() {
  my $g = Google::Voice->new->login($User,$Pass);
  # Send sms
  #$g->send_sms(5555555555 => 'Hello friend!');
   
  # Error code from google on fail
  #print $@ if !$g->send_sms('invalid phone' => 'text message');
   
  # connect call & cancel it
  #my $call = $g->call('+15555555555' => '+14444444444');
  #$call->cancel;
   
  # Print all sms conversations
  foreach my $sms ($g->sms) {
      print $sms->name;
      print $_->time, ':', $_->text, "\n" foreach $sms->messages;
   
      # Delete conversation
  #    $sms->delete;
  }
   
  # loop through voicemail messages
  foreach my $vm ($g->voicemail) {
   
      # Name, number, and transcribed text
      print $vm->name . "\n";
      print $vm->meta->{phoneNumber} . "\n";
      print $vm->text . "\n";
   
      # Download mp3
  #    $vm->download->move_to($vm->id . '.mp3');
   
      # Delete
  #    $vm->delete;
  }
}

sub main() {
  initg();
  test();
}

main();

__END__

-----------------------------------

http://github.com/tempire/perl-google-voice

DEPENDENCIES
  IO::Socket::SSL
  Mojo::Base 
  Mojo::ByteStream
  Mojo::JSON
  Mojo::UserAgent

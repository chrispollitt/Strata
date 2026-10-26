#!/usr/bin/perl

use Modern::Perl '2018';
use experimental 'signatures';
use Net::IMAP::Simple;
use Net::SMTP;
use Email::MIME;
use Data::Dumper;
use File::Slurp;
use Foo_Bar;
use strict;
use warnings; no warnings  'experimental';
binmode(STDOUT, ":utf8");

our $Host = 'gmail.com';
our $User = undef;
our $Pass = undef;

sub initg() {
  ($User,$Pass) = foo($Host);
}

sub check() {
  # Create the object
  my $imap = Net::IMAP::Simple->new(
    'imap.' . $Host,
    port    => 993,
    use_ssl => 1,
  ) ||  die "Unable to connect to IMAP: $Net::IMAP::Simple::errstr\n";
   
  # Log on
  if(!$imap->login($User, $Pass)) {
    print STDERR "IMAP login failed: " . $imap->errstr . "\n";
    exit(64);
  }
   
  # Print the subject's of all the messages in the INBOX
  my $nm = $imap->select('INBOX');   
  print "Info: inbox listing:\n";
  for(my $i = 1; $i <= $nm; $i++) {
    my $star = " ";
    $star    = "*" unless($imap->seen($i));  # Unread      
    my $msg  = Email::MIME->new(join '', @{ $imap->get($i) } ); 
    print "--------------------------------------------\n";    
    printf("%s[%03d] %s %s\n", $star, $i, $msg->header('From'), $msg->header('Subject'));
#    print "--body 0:\n" . $msg->body . "\n" if(length $msg->body);
    my $j=1;
    $msg->walk_parts( sub {
      my ($part) = @_;
      return if $part->subparts; # multipart
      print "content_type: " . $part->content_type . "\n";
      if ( ($part->content_type =~ m,text/plain,i) and (length $part->body)) {
#        print "--body $j:\n" . $part->body . "\n";
      } elsif(
        (defined $part->filename) and 
        ($part->filename =~ /\.(pdf)$/i) and 
        (defined $part->body) and
        (length $part->body)
      ) {
        write_file($ENV{HOME} . '/Downloads/' . $part->filename, $part->body);
      }
      $j++;
    });
  }
  
  # Logout
  $imap->quit;
}

sub sendmsg($to, $subject, $body) {
  # Create the object
  my $smtp = Net::SMTP->new(
    'smtp.' . $Host,
    Port    => 465,
    SSL     => 1,
  ) ||  die "Unable to connect to SMTP: $@\n";

  # Log on
  if(!$smtp->auth($User, $Pass)) {            # (authenticate)
    print STDERR "SMTP Login failed: " . $smtp->message() . "\n";
    exit(64);
  }
  
  # Send message
  $smtp->mail($User);                         # Create new message
  $smtp->to($to);                            # To
  $smtp->data();                              # .
  $smtp->datasend("To: $to\n");               # To
  $smtp->datasend("Subject: $subject\n");     # Subject
  $smtp->datasend("\n");                      # (end of headers)
  for my $line (split(/\n/, $body)) {         #   
    $smtp->datasend("$line\n");               # Body 
  }                                           #
  $smtp->dataend();                           # (end of body)
  print "Info: message sent\n";
  
  # Logout
  $smtp->quit;
}

sub main() {
  my $to      = 't0ph3r1967@aim.com';
  my $subject = 'Hello!';
  my $body    = <<"_EOF_";
Hello there,

How are you?

Take care.
_EOF_

  initg();
  check();
#  sendmsg($to, $subject, $body);
}

main();

__END__

------------------

Incoming Mail (IMAP) Server     : imap.gmail.com
Incoming Port                   : 993
Incoming Requires SSL           : Yes
Incoming Requires Authentication: Yes
Outgoing Mail (SMTP) Server     : smtp.gmail.com
Outgoing Port for SSL           : 465
Outgoing Port for TLS/STARTTLS  : 587
Outgoing Requires SSL           : Yes
Outgoing Requires TLS           : Yes (if available)
Outgoing Requires Authentication: Yes
Full Name                       : Chris Pollitt
Account Name                    : chris.pollitt@gmail.com
Password                        : (secret)

-----------------

From         Chris Pollitt <chris.pollitt@gmail.com>
To           Michelle Houle <michelle.houle@gmail.com>
CC           .
Bcc          .
Date         Mon, 20 Sep 2021 08:30:28 -0700
Message-ID   <CACNjb9C=x+4L_zQ0zoMzf683B7QhBDqGorA12W3U5-e23rE1+A@mail.gmail.com>
Subject      Hello

-----------------

Return-Path: <chris.pollitt@gmail.com>
Received: from localhost.localdomain (node-1w7jr9qucxmbekjovqwql5nh6.ipv6.telus.net. [2001:569:7d25:f100:2c1d:331a:b9b6:631a])
        by smtp.gmail.com with ESMTPSA id h6sm526651pji.6.2021.09.27.17.32.37
        for <t0ph3r1967@aim.com>
        (version=TLS1_3 cipher=TLS_AES_256_GCM_SHA384 bits=256/256);
        Mon, 27 Sep 2021 17:32:37 -0700 (PDT)
Message-ID: <615262a5.1c69fb81.5ca2c.2ab8@mx.google.com>
Date: Mon, 27 Sep 2021 17:32:37 -0700 (PDT)
From: chris.pollitt@gmail.com
To: t0ph3r1967@aim.com
Subject: hello

-------------

i Net-IMAP-Simple-1.2212-0/
i Email-Date-Format-1.005-0/
i Email-Simple-2.216-0/
i IO-Socket-SSL-2.072-0/
i libnet-3.13-0/
i Email-Address-XS-1.04-0/
i Text-Unidecode-1.30-0/
i Email-MIME-ContentType-1.026-0/
i Capture-Tiny-0.48-0/
i Email-MIME-Encodings-1.315-0/
i Email-MessageID-1.406-0/
i MIME-Types-2.21-0/
i Email-MIME-1.949-0/
#!/usr/bin/perl

use warnings;
use strict;
use MIME::Base64;

use FindBin;
use lib $FindBin::Bin;
use rottweiler;

my $encoded_file = shift @ARGV;
my $confirmed_file = shift @ARGV;

open my $confirmed_handler,$confirmed_file or die $!;
open my $encoded_handler,$encoded_file or die $!;

my $confirmed_blocks = {};

while (<$confirmed_handler>) {
    s#\n##;
    $confirmed_blocks->{$_} = 1;
}
close $confirmed_handler;

print add_overhead();

while(<$encoded_handler>) {
    m#.{22}\d{10}(\d{10})(.*)\n#;
    my $packet_number = decode_base64(substr($2, 0, $1 + 0));
    if (!exists $confirmed_blocks->{$packet_number}) {
        print $_;
    }
}

print add_overhead();

close $encoded_handler;

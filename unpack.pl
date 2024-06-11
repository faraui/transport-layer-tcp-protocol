#!/usr/bin/perl

use warnings;
use strict;
use MIME::Base64;

use FindBin;
use lib $FindBin::Bin;
use rottweiler;

check_received_directory();

my $filename = shift @ARGV;

open my $input_handler,"$filename" or die $!;

my $block_storage = {};

my $metadata_storage = {};


while (<$input_handler>) {
    decode_block($_,$block_storage,$metadata_storage)
}

close $input_handler;

set_block_count($metadata_storage,$block_storage);

check_for_uncorrupted($metadata_storage);

write_confirmed_file($block_storage,$metadata_storage->{'filename'});

print_statistics($metadata_storage);

decode_file($block_storage,$metadata_storage);


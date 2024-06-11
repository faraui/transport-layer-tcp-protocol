#!/usr/bin/perl

use warnings;
use strict;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use MIME::Base64;
use File::Basename;
use FindBin;
use lib $FindBin::Bin;
use rottweiler;


my $BLOCK_SIZE = 512;

my $filename = shift @ARGV;

my($encoded_filename, $directories, $suffix) = fileparse($filename);

$encoded_filename = $encoded_filename.$suffix;

print STDERR "Encoding $encoded_filename...\n";


open my $input_handler,"$filename" or die $!;

my $base64_line;
{
    $/ = undef;
    $base64_line = encode_base64(<$input_handler>);
}
$base64_line =~ s#\n##g;

my $blocks = [];

@{$blocks} = unpack("(A$BLOCK_SIZE)*", $base64_line);

my $block_counter;

init_block_counter(\$block_counter);

my $block_count = scalar @{$blocks};

my $headers = [];

push @{$headers}, gen_header($block_counter);
push @{$headers}, gen_header($block_count);
push @{$headers}, gen_header($encoded_filename);

my $header_count = scalar @{$headers};

print add_overhead();

for my $payload (@{$blocks}) {
    my $block_line = sprintf("%010d", $header_count + 1).gen_header($block_counter);
    for (my $header_number = 0; $header_number < $header_count; $header_number++) {
        $block_line = $block_line.$headers->[$header_number];
    }
    $block_line = $block_line.$payload;
    my $signed_block_line = md5_base64($block_line)."$block_line";
    
    print "$signed_block_line\n";

    block_counter_increment(\$block_counter);
}

print add_overhead();

print STDERR "File successfully encoded\nTotal blocks:\t\t".($block_counter)."\n";



#!/usr/bin/perl

package rottweiler;

use warnings;
use strict;
use MIME::Base64;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Data::Dumper;

use Exporter qw{ import };

our @EXPORT = qw { 
                    add_overhead
                    gen_header
                    block_counter_increment
                    init_block_counter
                    decode_block
                    decode_file
                    print_statistics
                    check_for_uncorrupted
                    write_confirmed_file
                    set_block_count
                    process_transmission
                    transmission_decode
                    check_received_directory
                 };

my $OVERHEAD_SIZE = 512;
my $OVERHEAD_COUNT = 10;
my $DEFAULT_CONFIRMED_FILE_NAME = "RECEIVED";
my $CONFIRMED_FILE_SUFFIX = ".confirmed.txt";
my $FILEPATH = "./received_files";

my $NO_EXIT = 1;

my $encoded_line = "";

sub add_overhead {
    my $overhead_string = "";
    for (my $overhead = 0; $overhead < $OVERHEAD_COUNT; $overhead ++) {
         $overhead_string = $overhead_string."1"x$OVERHEAD_SIZE;
    }
    $overhead_string = $overhead_string."\n";
}    

sub gen_header {
    my $header_value = shift;
    my $encoded_header_value = encode_base64($header_value);
    $encoded_header_value =~ s#\n##;
    my $header_length = sprintf("%010d",length($encoded_header_value));
    my $header = $header_length.$encoded_header_value;
    $header =~ s#\n##;
    return $header;

}


sub block_counter_increment {
    my $block_counter = shift;
    ${$block_counter}++;
}

sub init_block_counter {
    my $block_counter = shift;
    ${$block_counter} = 0;  
}

sub decode_block {
    my $block = shift;
    my $block_storage = shift;
    my $metadata_storage = shift;

    if($block =~ m#(.{22})(.*)\n#) {
        if (md5_base64($2) eq $1) {
            my $envelope = $2;
            $envelope =~ m#(\d{10})(.*)#;
            my $header_counter = $1 + 0;
            my $headers_and_payload = $2;
            my $header = [];

            for (my $header_number = 0; $header_number < $header_counter - 1; $header_number++) {
                $headers_and_payload =~ m#(\d{10})(.*)#;
                push @{$header}, decode_base64(substr($2, 0, $1 + 0));
                $headers_and_payload = substr($headers_and_payload, $1 + 10);
            }

            $headers_and_payload =~ m#(\d{10})(.*)#;
            $metadata_storage->{'filename'} =  decode_base64(substr($2, 0, $1));
            $metadata_storage->{'total_block_count'} = $header->[2];
            $metadata_storage->{'first_block_number'} = $header->[1];
            my $payload = substr($headers_and_payload, $1 + 10);

            $block_storage->{$header->[0]} = [$payload, $header->[1], $header->[2]];
            return 0;
        } else {
            print STDERR "Checksum failed\n";
            return 1;
        } 
    } else {
        print STDERR "Corrupted block detected\n";
        return 1;
    }

}

sub decode_file {
    my $block_storage = shift;
    my $metadata_storage = shift;
    my $no_exit = shift || 0;
    if ($metadata_storage->{'block_counter'} == $metadata_storage->{'total_block_count'}) {
        open my $output_file,">$FILEPATH/$metadata_storage->{'filename'}" or die $!;
        print $output_file decode_base64($encoded_line);
        print STDERR "All blocks are confirmed, file successfully decoded\n";
        close $output_file;
        exit 0 if !$no_exit;
    } else {
        print STDERR "Certain blocks were corrupted during transmition.\nSend confirmed.txt to the transmission point and run resend.pl\n";
        exit 1 if !$no_exit;
    } 
}

sub print_statistics {
    my $metadata_storage = shift;
    print STDERR "File name:\t\t\t$metadata_storage->{'filename'}\n";
    print STDERR "Total blocks:\t\t\t$metadata_storage->{'total_block_count'}\n";
    print STDERR "First block number:\t\t$metadata_storage->{'first_block_number'}\n";
    print STDERR "Received blocks:\t\t$metadata_storage->{'block_counter'}\n";
}

sub set_block_count {
    my $metadata_storage = shift;
    my $block_storage = shift;
    $metadata_storage->{'block_counter'} = scalar (keys %{$block_storage});
}

sub check_for_uncorrupted {
    my $metadata_storage = shift;
    if (!defined $metadata_storage->{'block_counter'} or $metadata_storage->{'block_counter'} == 0) {
        print STDERR "No uncorrupted blocks found\nCheck source file\n";
        exit 1;
    }
}

sub write_confirmed_file {
    my $block_storage = shift;
    my $confirmed_file_name = shift || $DEFAULT_CONFIRMED_FILE_NAME;
    open my $confirmed_file,">$FILEPATH/$confirmed_file_name$CONFIRMED_FILE_SUFFIX" or die $!;
    $encoded_line = "";
    for my $line_key (sort { sprintf("%010d", $a) <=> sprintf("%010d", $b) } keys %{$block_storage}) {
        append_encoded_line($block_storage->{$line_key}->[0]);
        print $confirmed_file "$line_key\n";
    }
    print STDERR "$confirmed_file_name$CONFIRMED_FILE_SUFFIX was created\n";
    close $confirmed_file;
}

sub append_encoded_line {
    my $next_line = shift;
    $encoded_line = $encoded_line.$next_line;
}

sub process_transmission {
    my $transmission = shift;
    my $data_storage = shift;

    my $metadata_storage = {};
    my $block_storage = {};
    my $decode_status = decode_block($transmission,$block_storage,$metadata_storage);
    return if $decode_status;
    append_data($data_storage,$metadata_storage,$block_storage);
    set_block_count($metadata_storage,$block_storage);
    if(!exists $data_storage->{$metadata_storage->{'filename'}}) {
        $data_storage->{$metadata_storage->{'filename'}} = {
            metadata => $metadata_storage,
            data => $block_storage,
        };
    } 
}

sub transmission_decode {
    my $data_storage = shift;
    my $filename = shift;

    print_statistics($data_storage->{$filename}->{'metadata'});

    write_confirmed_file($data_storage->{$filename}->{'data'},$filename);
    if ($data_storage->{$filename}->{'metadata'}->{'block_counter'} == $data_storage->{$filename}->{'metadata'}->{'total_block_count'}) {
        decode_file($data_storage->{$filename}->{'data'},$data_storage->{$filename}->{'metadata'},$NO_EXIT);
        delete $data_storage->{$filename};
        print STDERR ".......".(keys %$data_storage);
    } 
   
}

sub append_data {
    my $data_storage = shift;
    my $metadata_storage = shift;
    my $block_data = shift;
    if(exists $data_storage->{$metadata_storage->{'filename'}}) {
        for my $saved_block (keys %{$block_data}){
            $data_storage->{$metadata_storage->{'filename'}}->{'data'}->{$saved_block} = $block_data->{$saved_block};
        }
        $data_storage->{$metadata_storage->{'filename'}}->{'metadata'}->{'block_counter'} = scalar (keys %{$data_storage->{$metadata_storage->{'filename'}}->{'data'}});
    } 
}

sub check_received_directory {
    if(-d $FILEPATH) {
        print STDERR "$FILEPATH exists, continue...\n";
    } elsif (-e $FILEPATH) {
        print STDERR "$FILEPATH is not a directory. Can not continue.\n";
    } else {
        mkdir $FILEPATH or die "Can't create $FILEPATH:$!\n";
        print STDERR "$FILEPATH was created, continue...\n";

    }
}

1;

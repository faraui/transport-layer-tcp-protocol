#!/usr/bin/perl

use warnings;
use strict;
use MIME::Base64;

use FindBin;
use lib $FindBin::Bin;
use rottweiler;

use IO::Socket qw(AF_INET AF_UNIX SOCK_STREAM SHUT_WR);

my $HOST = '127.0.0.1';
my $PORT = 20000;
my $PROTO = 'tcp';

my $server = IO::Socket->new(
    Domain => AF_INET,
    Type => SOCK_STREAM,
    Proto => $PROTO,
    LocalHost => $HOST,
    LocalPort => $PORT,
    ReusePort => 1,
    Listen => 5,
) or die "Can not open socket: $IO::Socket::errstr";

print "$PROTO server running on $HOST:$PORT \n";

my $data_storage = {};

check_received_directory();

while (1) {
    my $connection = $server->accept();
    my $client_address = $connection->peerhost();
    my $client_port = $connection->peerport();
    print STDERR "Connection from $client_address:$client_port\n";

    while(<$connection>) {
        process_transmission($_,$data_storage);
    }
    for my $received_file (keys %{$data_storage}) {
        transmission_decode($data_storage,$received_file);
    }
}

$server->close();

print STDERR "Server stopped\n";

#!/usr/bin/perl -w

use strict;

use lib qw(./lib);

use Test::More tests => 3;

BEGIN { use_ok('Text::vCard::Addressbook'); }

my $address_book
    = Text::vCard::Addressbook->new( { 'source_file' => 't/quoted.vcf', } );

ok( $address_book, "Got an address book object" );

foreach my $vcard ( $address_book->vcards() ) {
    my $addresses = $vcard->get( { 'node_type' => 'ADR' } );
    foreach my $address ( @{$addresses} ) {
        is( $address->street(),
            'A street on a quoted line',
            'Got full (quoted address)'
        );
    }
}


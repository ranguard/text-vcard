#!/usr/bin/perl -w

use strict;

use lib qw(./lib);

use Test::More tests => 7;

# Check we can load module
BEGIN { use_ok('Text::vCard::Addressbook'); }

my $card_type = 'encoding.vcf';

ok( $card_type, "Running from $card_type" );
my $adbk = Text::vCard::Addressbook->new( { source_file => "t/$card_type" } );
isa_ok( $adbk, 'Text::vCard::Addressbook' );
my $vcards = $adbk->vcards();

is( scalar( @{$vcards} ), 1, "$card_type has 1 vcards as expected" );
my $vcard = $vcards->[0];
is( $vcard->get('fn')->[0]->value(),
    'Nathan Paul Christiansen I',
    "$card_type has fn data correct"
);

# print Dumper($vcard);
my $a = $vcard->get(
    {   'node_type' => 'ADR',
        'types'     => 'work',
    }
)->[0];
is( $a->street(),
    "Software Development\r\n333 West River Park Drive",
    'Match on street'
);
is( $a->city(), 'Provo', 'Match on city' );


#!/usr/bin/perl -w

use strict;

use lib qw(./lib);

use Test::More tests => 17;

# Check we can load module
use Data::Dumper;
BEGIN { use_ok('Text::vCard::Addressbook'); }

my @card_types = qw(evolution.vcf apple_2.1_unicode.vcf apple_version3.vcf);

foreach my $card_type (@card_types) {
    ok( $card_type, "Running from $card_type" );
    my $adbk
        = Text::vCard::Addressbook->new( { source_file => "t/$card_type" } );
    isa_ok( $adbk, 'Text::vCard::Addressbook' );
    my $vcards = $adbk->vcards();

    is( scalar( @{$vcards} ), 1, "$card_type has 1 vcards as expected" );
    my $vcard = $vcards->[0];
    is( $vcard->get('fn')->[0]->value(),
        'T-firstname T-surname',
        "$card_type has fn data correct"
    );

    # print Dumper($vcard);
    my $t = $vcard->get(
        {   'node_type' => 'tel',
            'types'     => 'home',
        }
    );
    is( $t->[0]->value(), '020 666 6666', 'got expected phone number' );
}

my $adbk = Text::vCard::Addressbook->new( { source_file => "t/notes.vcf" } );
my $vcards = $adbk->vcards();
my $note   = $vcards->[0]->note;
is( $note,
    '@prefix nasty <note>; with ; added into it and\n@prefix del: \n"; ]];\n];\n.',
    'Got note ok'
);


#!/usr/bin/perl -w

use strict;

use lib qw(./lib);

use Digest;

use Test::More tests => 5;

BEGIN { use_ok('Text::vCard::Addressbook'); }

my $address_book
    = Text::vCard::Addressbook->new( { 'source_file' => 't/base64.vcf', } );

ok( $address_book, "Got an address book object" );

my ($vcard) = ( $address_book->vcards );
ok( $vcard, 'vCard is present' );

my ($photo) = $vcard->get('photo');
ok( $photo, 'Photo is present' );

# open my $fh, '>/tmp/victoly.gif';
# binmode $fh;
# print $fh $photo->value;
# close $fh;

my $match
    = 'f80d7eda8ae7fd34eac2cc9f05dee6d5615a40d48e69f4541f7eb4f9bba050b7';

my $ctx = Digest->new('SHA-256');
$ctx->add( $photo->value );

is( $ctx->hexdigest, $match, 'SHA-256 sum of photo matches' );

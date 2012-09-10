#!/usr/bin/perl -w

use strict;

use lib qw(./lib);

use Test::More tests => 31;
use Data::Dumper;

# Check we can load module
BEGIN { use_ok('Text::vCard'); }
BEGIN { use_ok('Text::vCard::Addressbook'); }

local $SIG{__WARN__} = sub { die $_[0] };

#######
# Test new()
#######

my $function
    = Text::vCard::new( 'foo::bar', { 'source_file' => 't/simple.vcf' } );
is( ref($function), 'foo::bar', 'Can use as a base class' );

my $hash = Text::vCard::new( { foo => 'bar' },
    { 'source_file' => 't/simple.vcf' } );
is( ref($hash), 'HASH', 'new() retruns HASH when supplied hash' );

eval { Text::vCard::new(undef); };
like( $@, qr/Use of uninitialized value/, 'Errors if no class supplied' );
$@ = 'foo';

my $adbk
    = Text::vCard::Addressbook->new( { 'source_file' => 't/simple.vcf' } );
my $vcard = $adbk->vcards()->[0];

#######
# Test add_node()
#######
eval { $vcard->add_node(); };
like(
    $@,
    qr/Must supply a node_type/,
    'Croak if add_node() not supplied with anything'
);

eval { $vcard->add_node( {} ); };
like(
    $@,
    qr/Must supply a node_type/,
    'Croak if add_node() not supplied with node_type'
);

my %data = (
    'params' => [ { 'type' => 'HOME,PREF', }, ],
    'value' =>
        ';;First work address - street;Work city;London;Work PostCode;CountryName',
);
my @d = ( \%data );

my $new_address = $vcard->add_node(
    {   'node_type' => 'ADR',
        'data'      => \@d,
    }
);
isa_ok( $new_address, 'Text::vCard::Node' );

######
# get_simple_type
######

is( $vcard->get_simple_type( 'tel', 'home' ), '020 666 6666' );

#######
# Test get_of_type()
#######

my $home_adds_pref = $vcard->get_of_type( 'addresses', [ 'home', 'pref' ] );

is( scalar( @{$home_adds_pref} ),
    2, 'get_of_type() types returns 2 not 3 addresses with array ref' );

is( $vcard->get_of_type('foo'),
    undef, 'nothing of this type found, undef returned' );

my $home_adds = $vcard->get_of_type( 'addresses', 'home' );

is( scalar( @{$home_adds} ),
    3, 'get_of_type() types returns 3 not 3 addresses with scalar' );

is( $vcard->get_of_type( 'addresses', 'foo' ),
    undef, 'Undef returned when no addresses available' );

is( ref($home_adds), 'ARRAY', 'Returns array ref when called in context' );

my @list = $vcard->get_of_type( 'addresses', 'pref' );
is( scalar(@list), 2, 'Got all 2 addresses from array' );

my @list_all = $vcard->get_of_type('addresses');
is( scalar(@list_all), 3, 'Got 3 addresses from array as expected' );

#######
# Test get()
#######

eval { $vcard->get(); };
like(
    $@,
    qr/You did not supply an element type/,
    'get() croaks is no params supplied'
);

my $addresses = $vcard->get( { 'node_type' => 'addresses' } );
my $also_addresses = $vcard->get('addresses');

ok( eq_array( $addresses, $also_addresses ),
    'get() with single element and node_type match'
);

my $home_adds_get = $vcard->get(
    {   'node_type' => 'addresses',
        'types'     => [ 'home', 'pref' ],
    }
);

is( scalar( @{$home_adds_get} ), 2, 'get() types returns 2 not 3 addresses' );

#####
# test the auto generated methods
#####

is( $vcard->FN(), 'T-firstname T-surname', 'autogen methods - got FN' );
is( $vcard->fullname('new name'),
    'new name', 'autogen methods - updated fullname' );
is( $vcard->fn(), 'new name', 'autogen methods - got new fn' );

# try adding a new one
is( $vcard->email(), undef,
    'autogen methods - undef for no email as expected' );
is( $vcard->email('n.e@body.com'),
    'n.e@body.com', 'autogen methods - new value set' );

is( $vcard->birthday('new bd'), 'new bd', 'autogen added with alias' );

######
#
######

my $names = $vcard->get( { 'node_type' => 'name' } );
is( $names->[0]->family(),
    'T-surname', 'got name - but this will be depreciated' );

my $names2 = $vcard->get( { 'node_type' => 'moniker' } );
is( $names2->[0]->family(), 'T-surname', 'got moniker' );

######
# get get_group()
######
my $adgroup = Text::vCard::Addressbook->new(
    { 'source_file' => 't/apple_version3.vcf' } );

my $adgr_vcards = $adgroup->vcards();

my $adgr_vcard = $adgr_vcards->[0];

my $item1_nodes = $adgr_vcard->get_group('item1');
is( scalar( @{$item1_nodes} ),
    2, 'get_group("item1") - got 2 nodes as arrayref - expected' );

my @item1_nodes_array = $adgr_vcard->get_group('item1');
is( scalar(@item1_nodes_array),
    2, 'get_group("item1") - got 2 nodes as array - expected' );

my $item2_abadr = $adgr_vcard->get_group( 'item2', 'X-AbADR' );
is( $item2_abadr->[0]->value(),
    'uk', 'get_group("item2","X-AbADR") - got value from node' );

eval { $adgr_vcard->get_group(); };

like(
    $@,
    qr/No group name supplied/,
    'get_group - carp if no group name supplied'
);


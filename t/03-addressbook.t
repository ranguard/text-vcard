#!/usr/bin/perl -w

use strict;
use Data::Dumper;

use lib qw(./lib);

use Test::More  tests => 13;

local $SIG{__WARN__} = sub { die $_[0] };

# Check we can load module
BEGIN { use_ok( 'Text::vCard::Addressbook' ); }

#####
# load
#####
my $load = Text::vCard::Addressbook->load(['t/simple.vcf']);
isa_ok($load,'Text::vCard::Addressbook');

eval {
	Text::vCard::Addressbook->load(['i/do/not/exist']);
};
like($@,qr/Unable to read file/,'load() - croak when file does not exist');

######
# new()
######

# Can we create an empty address book
my $newadbk = Text::vCard::Addressbook->new();
isa_ok($newadbk,'Text::vCard::Addressbook');

eval{
	Text::vCard::Addressbook->new({'source_file' => 'i/do/not/exist'});
};
like($@,qr/Unable to read file/,'new() - croak when unable to read file');

eval {
	Text::vCard::Addressbook::new(undef);
};
like($@,qr/Use of uninitialized value/,'new() - ok error when no proto supplied');

my $foo = Text::vCard::Addressbook::new('foo::bar');
is(ref($foo),'foo::bar','new() - Can use as a base class');

my $hash = Text::vCard::Addressbook::new({foo => 'bar'});
is(ref($hash),'HASH','new() - retruns HASH when supplied hash');

eval {
  Text::vCard::Addressbook->new({ 'source_file' => 't/mix_type.vcf'});
};
like($@,qr/This file contains FOO/,'new() - carp on non VCARD format');
#####
# add_vcard()
#####
# Create a new vCard
my $vcard = $newadbk->add_vcard();
isa_ok($vcard,'Text::vCard');

# Add a node to it
my $address = $vcard->add_node({
	'node_type' => 'ADR',
});

# Add some data to the address.
$address->street('19 The mews');
$address->city('Buffyvill');

#####
# vcards
#####
# Now get it out of the address book
my $card_a = $newadbk->vcards();
is(ref($card_a),'ARRAY','vcards() - returns array ref when in context');
is($card_a->[0]->get({ 'node_type' => 'ADR'})->[0]->street(),'19 The mews','exstracted address ok'),

my @vcard_list = $newadbk->vcards();
is(scalar(@vcard_list),1,'vcards() returns array when in context');



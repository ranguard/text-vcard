#!/usr/bin/perl -w

use strict;

use lib qw(./lib);

use Test::More tests => 10;

use Data::Dumper;

# Check we can load module
BEGIN { use_ok('Text::vCard::Addressbook'); }

local $SIG{__WARN__} = sub { die $_[0] };

my @data = (
    'BEGIN:VCARD',
    'item1.X-ABADR:uk',
    'item2.X-ABADR:uk',
    'N:T-surname;T-first;;;',
    'TEL;pref;home:020 666 6666',
    'TEL;cell:0777 777 7777',
    'item2.ADR;work:;;Test Road;Test City;;Test Postcode;Test Country',
    'item1.ADR;TYPE=pref,home:;;Pref Test Road;Pref Test City;;Pref Test Postcode;Pref Test Country',
    'VERSION:3.0',
    'FN:T-firstname T-surname',
    'END:VCARD',
);

#######
# Test new()
#######
my $adbk = Text::vCard::Addressbook->new(
    { 'source_file' => 't/apple_version3.vcf' } );

my $vcf = $adbk->export();

#print $vcf;
like( $vcf, qr/TYPE=work/, 'export() - added type def' );

my @lines = split( "\r\n", $vcf );

is( $lines[0],       'BEGIN:VCARD', 'export() - First line correct' );
is( $lines[$#lines], 'END:VCARD',   'export() - Last line correct' );

$adbk->set_encoding('utf-8');
@data = (
    'BEGIN:VCARD',
    'item1.X-ABADR;charset=utf-8:uk',
    'item2.X-ABADR;charset=utf-8:uk',
    'N;charset=utf-8:T-surname;T-first;;;',
    'TEL;charset=utf-8;TYPE=pref,home:020 666 6666',
    'TEL;charset=utf-8;TYPE=cell:0777 777 7777',
    'item2.ADR;charset=utf-8;TYPE=work:;;Test Road;Test City;;Test Postcode;Test Country',
    'item1.ADR;charset=utf-8;TYPE=pref,home:;;Pref Test Road;Pref Test City;;Pref Test Postcode;Pref Test Country',
    'VERSION;charset=utf-8:3.0',
    'FN;charset=utf-8:T-firstname T-surname',
    'END:VCARD',
);
@lines = split( "\r\n", $adbk->export() );
is_deeply( \@lines, \@data,
    'set_encoding() - returned data matched that expected' );

#is_deeply(\@lines,\@data,'export() - returned data matched that expected');

#my $notes = Text::vCard::Addressbook->new({ 'source_file' => 't/notes.vcf'});
#print Dumper($notes);
#my $res = $notes->export();
#print Dumper($res);

{
    my $ab = Text::vCard::Addressbook->new();
    is $ab->export, '', 'export empty addressbook';
    my $vcard = $ab->add_vcard;
    isa_ok $vcard, 'Text::vCard';
    like $ab->export, qr{^BEGIN:VCARD\s+END:VCARD$}, 'single empty vcard';
    $vcard->fullname('Foo Bar');
    $vcard->EMAIL('foo@bar.com');
    my $node = $vcard->add_node(
        {   'node_type' => 'TEL',

            # fields => ['TYPE'],
            # data   => { TYPE => 'Work' },
        }
    );
    isa_ok $node, 'Text::vCard::Node';

    #$vcard->TEL('01-23456789');
    eval { $vcard->random_field('Something else'); };
    like $@,
        qr{Can't locate object method "random_field" via package "Text::vCard"},
        'exception';

    #diag $ab->export;
}


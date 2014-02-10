#!/usr/bin/perl -w

use Test::Most;
use lib qw(./lib);
use Data::Dumper;

# Check we can load module
BEGIN { use_ok('Text::vCard::Addressbook'); }

local $SIG{__WARN__} = sub { die $_[0] };

#######
# Test new()
#######
my $adbk = Text::vCard::Addressbook->new(
    { 'source_file' => 't/apple_version3.vcf' } );

my $vcf = $adbk->export();

like( $vcf, qr/TYPE=work/, 'export() - added type def' );

my @lines = split( "\x0D\x0A", $vcf );    # \x0D\x0A == \r\n

is( $lines[0],       'BEGIN:VCARD', 'export() - First line correct' );
is( $lines[$#lines], 'END:VCARD',   'export() - Last line correct' );

$adbk->set_encoding('utf-8');
my @data = (
    'BEGIN:VCARD',
    'item1.X-ABADR:uk',
    'item2.X-ABADR:uk',
    'N:T-surname;T-first;;;',
    'TEL;TYPE=home,pref:020 666 6666',
    'TEL;TYPE=cell:0777 777 7777',
    'item2.ADR;TYPE=work:;;Test Road;Test City;;Test Postcode;Test Country',
    'item1.ADR;TYPE=home,pref:;;Pref Test Road;Pref Test City;;Pref Test Postcod',
    ' e;Pref Test Country',
    'VERSION:3.0',
    'FN:T-firstname T-surname',
    'END:VCARD',
);
@lines = split( "\x0D\x0A", $adbk->export() );    # \x0D\x0A == \r\n
is_deeply(
    [ sort @lines ],
    [ sort @data ],
    'set_encoding() - returned data matched that expected'
);

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
    like $ab->export, qr{^BEGIN:VCARD\s+END:VCARD\x0D\x0A$},
        'single empty vcard';
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

done_testing;

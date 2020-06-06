use Test::Most;
use Text::vCard::Addressbook;

my $address_book = Text::vCard::Addressbook->load( ['t/google_contacts.vcf'] );
my $vcard        = $address_book->vcards->[0];
my $phone_node   = $vcard->get( { 'node_type' => 'phones' } )->[1];
my $types        = $phone_node->types;
is_deeply $types, [ 'cell', 'text' ], 'types()';

done_testing;

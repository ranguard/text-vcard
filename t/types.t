use Test::Most;
use Text::vCard::Addressbook;

my $address_book = Text::vCard::Addressbook->load( ['t/complete.vcf'] );
my $vcard        = $address_book->vcards->[0];
my $phone_node   = $vcard->get( { 'node_type' => 'phones' } )->[0];
my $types        = $phone_node->types;
is_deeply $types, ['work'], 'types()';

done_testing;

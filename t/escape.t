use Test::Most;
use Text::vCard::Addressbook;
use Path::Class;

my $in_file      = file('t/complete.vcf');
my $address_book = Text::vCard::Addressbook->load( [$in_file] );
my $vcard        = $address_book->vcards->[0];
is $vcard->fullname, 'Bruce Banner, PhD', ', was not escaped';

done_testing;

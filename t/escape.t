use Test::Most;
use Text::vCard::Addressbook;
use Path::Tiny;

my $in_file      = path('t/complete.vcf');
my $address_book = Text::vCard::Addressbook->load( [$in_file] );
my $vcard        = $address_book->vcards->[0];
is $vcard->fullname, 'Bruce Banner, PhD', ', was not escaped';

done_testing;

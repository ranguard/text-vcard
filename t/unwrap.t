use Test::Most;

use Directory::Scratch;
use Path::Tiny;
use vCard;

# vCard files should have lines that are a max of 75 octets.  When they are too
# long the lines are wrapped.  The first character on continued line must be a
# space or a tab.  This test makes sure that works.
# see http://tools.ietf.org/search/rfc6350#section-3.2

my $in_file = path( 't', 'unwrap.vcf' );
note "Importing $in_file with Addressbook->load()";

my $address_book = Text::vCard::Addressbook->load( [$in_file] );
my $vcard = $address_book->vcards->[0];

my $expected_content = $in_file->slurp_utf8;
my $actual_content   = $vcard->as_string();

is $actual_content, $expected_content, 'vCard->as_string()';
is $address_book->export(), $actual_content, 'Addressbook->export()';

done_testing;

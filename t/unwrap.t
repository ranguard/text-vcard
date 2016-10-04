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

# the order in the vcard keys is not preserved so we wil test the only the wrapped lines
my $N    =  qr(/(N;CH[^\r]\r\n(?:[ \t][^\r]*\r\n)*)/s);
my $ADR  =  qr(/(ADR;[^\r]\r\n(?:[ \t][^\r]*\r\n)*)/s);
my $NOTE =  qr(/(NOTE[^\r]\r\n(?:[ \t][^\r]*\r\n)*)/s);


is $actual_content =~ $N,$expected_content =~ $N, 'vCard->as_string() N ?';
is $actual_content =~ $ADR,$expected_content =~ $ADR, 'vCard->as_string() ADR key?';
is $actual_content =~ $NOTE,$expected_content =~ $NOTE, 'vCard->as_string() NOTE key?';

is $address_book->export(), $actual_content, 'Addressbook->export()';

done_testing;

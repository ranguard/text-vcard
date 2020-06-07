use Test::Most;
use Text::vCard::Addressbook;

my $address_book = Text::vCard::Addressbook->load( ['t/label.vcf'] );
my $address      = $address_book->vcards->[0]->get('ADR')->[0]->label();
ok( $address, "422 S. New Lane\\nStoughton, MA 02072\\nUS" );
done_testing;
